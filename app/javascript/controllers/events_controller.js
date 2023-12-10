import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

const DATE_FORMAT = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "short"
})

// Drives the single events page: loads a page of events from /api/events and
// wires up the create / show / join / delete actions.
//
// All cell content is written with textContent rather than innerHTML — event
// names and descriptions are user supplied, and the previous template-literal
// markup injected them unescaped.
export default class extends Controller {
  static targets = [
    "tableBody", "summary", "emptyState", "errorState",
    "pager", "pageLabel", "previousButton", "nextButton"
  ]

  // Only these may be invoked from `data-action-name`; the old code looked the
  // method up straight from the DOM attribute.
  static ENTRY_POINTS = ["index"]

  connect() {
    this.page = 1
    this.meta = null

    const entryPoint = this.element.dataset.actionName
    if (this.constructor.ENTRY_POINTS.includes(entryPoint)) {
      this[entryPoint]()
    } else {
      console.error(`Unknown events entry point: ${entryPoint}`)
    }

    this.createForm = document.getElementById("create-event-form")
    if (this.createForm) {
      this.boundSubmit = this.submitCreateForm.bind(this)
      this.createForm.addEventListener("submit", this.boundSubmit)
    }
  }

  disconnect() {
    if (this.createForm && this.boundSubmit) {
      this.createForm.removeEventListener("submit", this.boundSubmit)
    }
  }

  // --- data ---------------------------------------------------------------

  get headers() {
    return {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content ?? ""
    }
  }

  async index() {
    try {
      const response = await fetch(`/api/events?page=${this.page}`, { headers: this.headers })
      if (!response.ok) throw new Error(`Request failed with ${response.status}`)

      const { events, meta } = await response.json()
      this.meta = meta
      this.render(events)
    } catch (error) {
      console.error("Error loading events:", error)
      this.tableBodyTarget.replaceChildren()
      this.errorStateTarget.classList.remove("d-none")
      this.summaryTarget.textContent = ""
    }
  }

  // --- rendering ----------------------------------------------------------

  render(events) {
    this.errorStateTarget.classList.add("d-none")
    this.tableBodyTarget.replaceChildren(...events.map((event) => this.buildRow(event)))
    this.emptyStateTarget.classList.toggle("d-none", events.length > 0)

    const total = this.meta?.total_count ?? events.length
    this.summaryTarget.textContent =
      total === 1 ? "1 event" : `${total} events`

    const pages = this.meta?.total_pages ?? 1
    this.pagerTarget.classList.toggle("d-none", pages <= 1)
    this.pageLabelTarget.textContent = `Page ${this.meta?.page ?? 1} of ${pages}`
    this.previousButtonTarget.disabled = (this.meta?.page ?? 1) <= 1
    this.nextButtonTarget.disabled = (this.meta?.page ?? 1) >= pages
  }

  buildRow(event) {
    const row = document.createElement("tr")
    row.id = `row-${event.id}`

    row.append(
      this.nameCell(event),
      this.textCell(this.formatDate(event.date)),
      this.textCell(event.location ?? ""),
      this.textCell(event.organizer?.email ?? ""),
      this.countCell(event.attendees_count ?? 0),
      this.actionsCell(event)
    )

    return row
  }

  nameCell(event) {
    const cell = document.createElement("td")

    const name = document.createElement("div")
    name.className = "fw-semibold"
    name.textContent = event.name
    cell.append(name)

    if (event.description) {
      const description = document.createElement("div")
      description.className = "small text-secondary text-truncate"
      description.style.maxWidth = "24rem"
      description.textContent = event.description
      cell.append(description)
    }

    return cell
  }

  textCell(value) {
    const cell = document.createElement("td")
    cell.className = "text-nowrap"
    cell.textContent = value
    return cell
  }

  countCell(value) {
    const cell = document.createElement("td")
    cell.className = "text-center"

    const badge = document.createElement("span")
    badge.className = "badge rounded-pill text-bg-secondary"
    badge.textContent = String(value)
    cell.append(badge)

    return cell
  }

  actionsCell(event) {
    const cell = document.createElement("td")
    cell.className = "text-end text-nowrap"

    cell.append(this.button("Details", "btn-outline-secondary", "events#show", event.id))

    if (event.editable) {
      cell.append(this.button("Delete", "btn-outline-danger", "events#delete", event.id))
    } else if (event.joined) {
      const joined = document.createElement("span")
      joined.className = "badge text-bg-success align-middle ms-1"
      joined.textContent = "Joined"
      cell.append(joined)
    } else {
      const join = this.button("Join", "btn-success", "events#join", event.id)
      join.id = `join-event-${event.id}`
      cell.append(join)
    }

    return cell
  }

  button(label, variant, action, eventId) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = `btn btn-sm ${variant} ms-1`
    button.dataset.action = `click->${action}`
    button.dataset.eventId = eventId
    button.textContent = label
    return button
  }

  formatDate(value) {
    if (!value) return "—"
    const parsed = new Date(value)
    return Number.isNaN(parsed.valueOf()) ? "—" : DATE_FORMAT.format(parsed)
  }

  // <input type="datetime-local"> yields wall-clock time with no zone, which
  // the server would read as UTC. Convert it in the browser, where the zone is
  // known, so 18:30 typed in Lahore is stored as 13:30Z and shown back as 18:30.
  toIsoWithOffset(localValue) {
    if (!localValue) return localValue
    const parsed = new Date(localValue)
    return Number.isNaN(parsed.valueOf()) ? localValue : parsed.toISOString()
  }

  // --- actions ------------------------------------------------------------

  create(clickEvent) {
    clickEvent.preventDefault()
    this.clearCreateErrors()
    this.createModal().show()
  }

  async submitCreateForm(submitEvent) {
    submitEvent.preventDefault()
    this.clearCreateErrors()

    const payload = Object.fromEntries(new FormData(this.createForm).entries())
    delete payload["authenticity_token"]

    const body = JSON.stringify({
      event: {
        name: payload["event[name]"],
        description: payload["event[description]"],
        location: payload["event[location]"],
        date: this.toIsoWithOffset(payload["event[date]"])
      }
    })

    try {
      const response = await fetch("/api/events", { method: "POST", headers: this.headers, body })
      const data = await response.json()

      if (!response.ok) return this.showCreateErrors(data)

      this.createModal().hide()
      this.createForm.reset()
      this.showAlert("Event created.")
      this.page = 1
      await this.index()
    } catch (error) {
      console.error("Error creating event:", error)
      this.showCreateErrors({ base: ["Something went wrong. Please try again."] })
    }
  }

  async show(clickEvent) {
    clickEvent.preventDefault()
    const eventId = clickEvent.currentTarget.dataset.eventId

    try {
      const response = await fetch(`/api/events/${eventId}`, { headers: this.headers })
      if (!response.ok) throw new Error(`Request failed with ${response.status}`)

      const { event } = await response.json()

      document.getElementById("show-event-title").textContent = event.name
      document.getElementById("show-event-description").textContent = event.description || "No description."
      document.getElementById("show-event-date").textContent = this.formatDate(event.date)
      document.getElementById("show-event-location").textContent = event.location ?? ""
      document.getElementById("show-event-organizer").textContent = event.organizer?.email ?? ""
      document.getElementById("show-event-attendees").textContent = String(event.attendees_count ?? 0)

      Modal.getOrCreateInstance(document.getElementById("showEventModal")).show()
    } catch (error) {
      console.error("Error loading event:", error)
      this.showAlert("Could not load that event.", "danger")
    }
  }

  async delete(clickEvent) {
    clickEvent.preventDefault()
    if (!window.confirm("Delete this event? This cannot be undone.")) return

    const eventId = clickEvent.currentTarget.dataset.eventId

    try {
      const response = await fetch(`/api/events/${eventId}`, { method: "DELETE", headers: this.headers })
      if (!response.ok) throw new Error(`Request failed with ${response.status}`)

      this.showAlert("Event deleted.")
      await this.index()
    } catch (error) {
      console.error("Error deleting event:", error)
      this.showAlert("Could not delete that event.", "danger")
    }
  }

  async join(clickEvent) {
    clickEvent.preventDefault()
    const eventId = clickEvent.currentTarget.dataset.eventId

    try {
      const response = await fetch(`/api/events/${eventId}/join`, { method: "POST", headers: this.headers })

      if (response.status === 409) return this.showAlert("You have already joined that event.", "warning")
      if (!response.ok) throw new Error(`Request failed with ${response.status}`)

      this.showAlert("You joined the event.")
      await this.index()
    } catch (error) {
      console.error("Error joining event:", error)
      this.showAlert("Could not join that event.", "danger")
    }
  }

  previousPage() {
    if (this.page <= 1) return
    this.page -= 1
    this.index()
  }

  nextPage() {
    if (this.page >= (this.meta?.total_pages ?? 1)) return
    this.page += 1
    this.index()
  }

  // --- chrome -------------------------------------------------------------

  createModal() {
    return Modal.getOrCreateInstance(document.getElementById("createEventModal"))
  }

  clearCreateErrors() {
    const box = document.getElementById("create-event-errors")
    box.classList.add("d-none")
    box.replaceChildren()
  }

  showCreateErrors(errors) {
    const box = document.getElementById("create-event-errors")
    const list = document.createElement("ul")
    list.className = "mb-0 ps-3"

    Object.entries(errors).forEach(([field, messages]) => {
      const texts = Array.isArray(messages) ? messages : [messages]
      texts.forEach((message) => {
        const item = document.createElement("li")
        item.textContent = field === "base" ? message : `${field.replace(/_/g, " ")} ${message}`
        list.append(item)
      })
    })

    box.replaceChildren(list)
    box.classList.remove("d-none")
  }

  showAlert(message, variant = "success") {
    const alertElement = document.getElementById("customAlert")
    const alertTextElement = document.getElementById("alertText")

    alertElement.className = `alert alert-${variant} shadow fade mb-0 show`
    alertTextElement.textContent = message

    clearTimeout(this.alertTimeout)
    this.alertTimeout = setTimeout(() => {
      alertElement.classList.remove("show")
      alertElement.classList.add("d-none")
    }, 3000)
  }
}
