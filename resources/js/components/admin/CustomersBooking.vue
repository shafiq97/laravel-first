<template>
    <div class="dashboard-container">
      <div class="dashboard-sidebar">
        <AdminDashboard />
      </div>

      <div class="admin-bookings-container">
        <!-- Calendar Section -->
        <div class="calendar-wrapper card shadow p-4 mb-4">
          <FullCalendar :options="calendarOptions" class="fc-custom" />
        </div>

        <!-- All Bookings Table Section -->
        <div class="bookings-table-wrapper card shadow p-4">
          <h4 class="mb-4">All Bookings</h4>
          <div class="table-responsive">
            <table class="table table-hover">
              <thead class="table-light">
                <tr>
                  <th>Customer</th>
                  <th>Date</th>
                  <th>Time</th>
                  <th>Service Type</th>
                  <th>Aircon Type</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(booking, index) in bookings" :key="index">
                  <td>{{ booking.customer?.name || 'N/A' }}</td>
                  <td>{{ formatTableDate(booking.date) }}</td>
                  <td>{{ booking.time }}</td>
                  <td>{{ booking.service_type }}</td>
                  <td>{{ booking.aircon_type }}</td>
                  <td>
                    <div class="dropdown">
                      <button class="btn btn-sm dropdown-toggle"
                              :class="'btn-' + getStatusColor(booking.status)"
                              type="button"
                              id="statusDropdown"
                              data-bs-toggle="dropdown"
                              aria-expanded="false">
                        {{ booking.status }}
                      </button>
                      <ul class="dropdown-menu" aria-labelledby="statusDropdown">
                        <li v-for="status in statusOptions" :key="status">
                          <a class="dropdown-item"
                             href="#"
                             @click.prevent="updateBookingStatus(booking, status)">
                            {{ status }}
                          </a>
                        </li>
                      </ul>
                    </div>
                  </td>
                  <td>
                    <button
                      class="btn btn-sm btn-outline-primary"
                      @click="viewBookingDetails(booking)"
                    >
                      View
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Booking Details Modal -->
        <div class="modal fade" id="bookingModal" tabindex="-1" aria-hidden="true">
          <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content">
              <div class="modal-header bg-primary text-white">
                <h5 class="modal-title">Booking Details</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
              </div>
              <div class="modal-body">
                <div v-if="currentBooking">
                  <div class="row">
                    <div class="col-md-6">
                      <h6 class="section-title">Customer Information</h6>
                      <p><strong>Name:</strong> {{ currentBooking.customer?.name || 'Not available' }}</p>
                      <p><strong>Email:</strong> {{ currentBooking.customer?.email || 'Not available' }}</p>
                      <p><strong>Phone:</strong> {{ currentBooking.customer?.phone || 'Not available' }}</p>
                      <p><strong>Address:</strong> {{ currentBooking.customer?.address || 'Not available' }}</p>
                    </div>
                    <div class="col-md-6">
                      <h6 class="section-title">Service Details</h6>
                      <p><strong>Date:</strong> {{ formatBookingDate(currentBooking.date) }}</p>
                      <p><strong>Time:</strong> {{ currentBooking.time }}</p>
                      <p><strong>Service Type:</strong> {{ currentBooking.service_type }}</p>
                      <p><strong>Aircon Type:</strong> {{ currentBooking.aircon_type }}</p>
                      <p><strong>Recurring Service:</strong> {{ currentBooking.recurring_service }}</p>
                      <p><strong>Status:</strong>
                        <span class="badge" :class="'bg-' + getStatusColor(currentBooking.status)">
                          {{ currentBooking.status }}
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>

  <script>
  import axios from 'axios';
  import AdminDashboard from './AdminDashboard.vue';
  import FullCalendar from '@fullcalendar/vue3';
  import dayGridPlugin from '@fullcalendar/daygrid';
  import { Modal } from 'bootstrap';

  export default {
    name: 'CustomersBooking',
    components: {
      AdminDashboard,
      FullCalendar
    },
    data() {
      return {
        bookings: [],
        selectedBookings: [],
        selectedDate: null,
        currentBooking: null,
        bookingModal: null,
        statusOptions: ['Booked', 'In Progress', 'Completed']
      };
    },
    computed: {
      calendarOptions() {
        return {
          plugins: [dayGridPlugin],
          initialView: 'dayGridMonth',
          height: 'auto',
          headerToolbar: {
            left: 'prev,next today',
            center: 'title',
            right: ''
          },
          events: this.bookings.map(booking => ({
            title: `${booking.customer?.name || 'Customer'} - ${booking.service_type}`,
            start: booking.date,
            extendedProps: booking,
            backgroundColor: this.getStatusColor(booking.status, true),
            borderColor: this.getStatusColor(booking.status, true)
          })),
          dateClick: this.handleDateClick
        };
      }
    },
    mounted() {
      this.bookingModal = new Modal(document.getElementById('bookingModal'));
      this.fetchBookings();
    },
    methods: {
      async fetchBookings() {
        try {
          const response = await axios.get('http://127.0.0.1:8000/api/admin/bookings');
          this.bookings = response.data;
        } catch (error) {
          console.error('Error fetching bookings:', error);
        }
      },
      async updateBookingStatus(booking, newStatus) {
        try {
          console.log('Updating booking:', booking.id, 'to status:', newStatus);

          const response = await axios.put(
            `http://127.0.0.1:8000/api/admin/bookings/${booking.id}/status`,
            { status: newStatus }
          );

          console.log('Update response:', response.data);

          // Update the local booking object
          booking.status = newStatus;

          // Force Vue reactivity by creating a new array
          this.bookings = this.bookings.map(b =>
            b.id === booking.id ? { ...b, status: newStatus } : b
          );

          // Show success message
          alert('Status updated successfully!');

          return response.data;
        } catch (error) {
          console.error('Error updating booking status:', error);
          alert(`Failed to update status: ${error.response?.data?.message || error.message}`);
          throw error;
        }
      },
      handleDateClick(info) {
        this.selectedDate = info.dateStr;
        this.selectedBookings = this.bookings.filter(booking => {
          const bookingDate = new Date(booking.date).toISOString().split('T')[0];
          return bookingDate === info.dateStr;
        });
        if (this.selectedBookings.length > 0) {
          this.currentBooking = this.selectedBookings[0];
          this.bookingModal.show();
        }
      },
      viewBookingDetails(booking) {
        this.currentBooking = booking;
        this.bookingModal.show();
      },
      formatBookingDate(dateString) {
        return new Date(dateString).toLocaleDateString('en-US', {
          weekday: 'long',
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
      },
      formatTableDate(dateString) {
        return new Date(dateString).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: 'numeric'
        });
      },
      getStatusColor(status, isCalendar = false) {
        const colors = {
          'Booked': isCalendar ? '#0d6efd' : 'primary',
          'In Progress': isCalendar ? '#ffc107' : 'warning',
          'Completed': isCalendar ? '#198754' : 'success',
        };
        return colors[status] || (isCalendar ? '#6c757d' : 'secondary');
      }
    }
  };
  </script>

  <style scoped>
.dashboard-container {
  display: flex;
  min-height: 100vh;
  background-image: url('/images/background.jpg');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  position: relative;
}

  .dashboard-sidebar {
    flex: 0 0 250px;
  }

  .admin-bookings-container {
    flex: 1;
    padding: 2rem;
    overflow-y: auto;
  }

  .calendar-wrapper {
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  }

  .bookings-table-wrapper {
    background: white;
    border-radius: 0.5rem;
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  }

  .fc-custom {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }

  .section-title {
    color: #0d6efd;
    border-bottom: 1px solid #dee2e6;
    padding-bottom: 0.5rem;
    margin-bottom: 1rem;
  }

  .badge {
    font-size: 0.875em;
    padding: 0.35em 0.65em;
    font-weight: 500;
  }

  .table th {
    font-weight: 600;
  }

  .table-responsive {
    overflow-x: auto;
  }

  .dropdown-toggle::after {
    margin-left: 0.5em;
  }

  .btn-warning {
    color: #000;
  }

  .btn-primary, .btn-success, .btn-danger {
    color: #fff;
  }

  .dropdown-item {
    cursor: pointer;
  }
  </style>
