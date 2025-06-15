<template>
  <div class="admin-login-container">
    <div class="login-card">
      <h2 class="text-center mb-4">Admin Login</h2>
      <form @submit.prevent="loginAdmin">
        <div class="mb-3">
          <label for="email" class="form-label">Email</label>
          <input
            type="email"
            class="form-control"
            id="email"
            v-model="email"
            required
          >
        </div>
        <div class="mb-3">
          <label for="password" class="form-label">Password</label>
          <input
            type="password"
            class="form-control"
            id="password"
            v-model="password"
            required
          >
        </div>
        <div v-if="errorMessage" class="alert alert-danger">
          {{ errorMessage }}
        </div>
        <button type="submit" class="btn btn-primary w-100" :disabled="loading">
          {{ loading ? 'Logging in...' : 'Login' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script>
import axios from 'axios';
export default {
  name: 'AdminLogin',
  data() {
    return {
      email: '',
      password: '',
      errorMessage: '',
      loading: false
    };
  },
  methods: {
    loginAdmin() {
      this.loading = true;
      this.errorMessage = '';

      // Hardcoded admin credentials
      if (this.email === 'admin@gmail.com' && this.password === 'admin12345') {
        localStorage.setItem('admin_token', 'fake_token'); // Simulating token storage

        // Set axios default header for admin requests
        axios.defaults.headers.common['Authorization'] = `Bearer fake_token`;

        this.$router.push('/admin/dashboard');
      } else {
        this.errorMessage = 'Invalid email or password.';
      }

      this.loading = false;
    }
  }
};
</script>

<style scoped>
.admin-login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 20px;
}

.login-card {
  background-color:#06A5FF;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  width: 100%;
  max-width: 400px;
}
</style>
