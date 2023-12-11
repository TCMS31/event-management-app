import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tableBody", "modalBody"];
  static HEADERS = {
    'Content-Type': 'application/json',
    "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
  }

  connect() {
    try {
      this[this.data.element.getAttribute('data-action-name')]();
    } catch(error) {
      console.error('Relevant function not found!', error);
    }
  }

  async index() {
    try {
      const response = await fetch("/api/events", { method: 'GET' });
      const data = await response.json();

      data.forEach((event) => {
        this.tableBodyTarget.appendChild(this.createEventRow(event));
      });
    } catch (error) {
      console.error("Error loading events:", error);
    }
  }

  async create(event) {
    event.preventDefault();

    const newModal = new bootstrap.Modal(document.getElementById("createEventModal"));
    newModal.show();

    const createEventForm = document.getElementById('create-event-form');
    createEventForm.addEventListener('ajax:success', (event) => {
      console.log("Form submission successful!");
      this.showAlert('Event created successfully!');
      this.tableBodyTarget.appendChild(this.createEventRow(event.detail[0]));
      newModal.hide();
    });
  }

  async show(event) {
    try {
      event.preventDefault();
      const eventId = event.target.dataset.eventId;
      console.log(eventId);

      const newModal = new bootstrap.Modal(document.getElementById("showEventModal"));
      const response = await fetch(`/api/events/${eventId}`, { method: 'GET', headers: this.constructor.HEADERS });
      const data = await response.json();

      document.getElementById('show-event-title').textContent = data.name;
      document.getElementById('show-event-id').textContent = data.id;
      document.getElementById('show-event-description').textContent = data.description || '';
      document.getElementById('show-event-date').textContent = data.date || '';
      document.getElementById('show-event-location').textContent = data.location || '';
      document.getElementById('show-event-organizer').textContent = data.organizer.email;
      newModal.show();
    } catch (error) {
      console.error("Error loading events:", error);
    }
  }

  async delete(event) {
    event.preventDefault();
    if (!confirm("Are you sure?")) return;

    const eventId = event.target.dataset.eventId;

    try {
      const response = await fetch(`/api/events/${eventId}`, { method: 'DELETE', headers: this.constructor.HEADERS });

      if (response.ok) {
        const rowToDelete = document.getElementById(`row-${eventId}`);
        if (rowToDelete) {
            const parentTable = rowToDelete.parentNode;
            parentTable.removeChild(rowToDelete);
        } else {
            console.error('Row with specified ID not found');
        }
      } else {
        throw new Error('Failed to delete');
      }
    } catch (error) {
      console.error("Error deleting event:", error);
    }
  }

  async join(event) {
    event.preventDefault();
    if (!confirm("Are you sure?")) return;

    const eventId = event.target.dataset.eventId;

    try {
      const response = await fetch(`/api/events/${eventId}/join`, { method: 'POST', headers: this.constructor.HEADERS });

      if (response.ok) {
        const joinEventLink = document.getElementById(`join-event-${eventId}`);
        if (joinEventLink) {
            this.showAlert('Event joined succesfully!');
            joinEventLink.remove();
        } else {
            console.error('Row with specified ID not found');
        }
      } else {
        throw new Error('Failed to join');
      }
    } catch (error) {
      console.error("Error joining event:", error);
    }
  }

  createColumn(data) {
    return `
    <td class="my-2">
      <div class="d-flex align-items-center text-light">
        <div class="ms-3">
          <p class="fw-bold mb-1">${data}</p>
        </div>
      </div>
    </td>
    `
  }

  createEventRow(event) {
    const row = document.createElement('tr');
    row.id = `row-${event.id}`
    row.innerHTML = `
      ${this.createColumn(event.id)}
      ${this.createColumn(event.name)}
      ${this.createColumn(event.description || '')}
      ${this.createColumn(event.date || '')}
      ${this.createColumn(event.location || '')}
      ${this.createColumn(event.organizer.email)}

      <td class="my-2 text-center">
      <button class='btn btn-light' data-action="click->events#show" data-event-id="${event.id}">Show</button>
      <button class='btn btn-light' data-action="click->events#edit" data-event-id="${event.id}">Edit</button>
      <button class='btn btn-light' data-action="click->events#delete" data-event-id="${event.id}">Delete</button>
      <button class='btn btn-light' data-event-id="${event.id}" id="join-event-${event.id}" data-action="click->events#join">Join</button>
      </td>
    `;

    return row;
  }


  hideAlert() {
    const alertElement = document.getElementById('customAlert');
    alertElement.classList.remove('show');
  }

  showAlert(message) {
    const alertElement = document.getElementById('customAlert');
    const alertTextElement = document.getElementById('alertText');

    alertTextElement.textContent = message;
    alertElement.classList.add('show');

    setTimeout(() => {
      this.hideAlert();
    }, 3000);
  }
}
