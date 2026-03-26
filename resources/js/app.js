import { createApp } from 'vue';
import { createPinia } from 'pinia';
import router from './router';
import App from './App.vue';
import vue3GoogleLogin from 'vue3-google-login';
import './bootstrap';

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.use(vue3GoogleLogin, {
  clientId: import.meta.env.VITE_GOOGLE_CLIENT_ID || 'dummy-client-id'
});

// Toast Notification
import Toast from "vue-toastification";
import "vue-toastification/dist/index.css";

const options = {
    position: "bottom-left",
    timeout: 3000,
    closeOnClick: true,
    pauseOnFocusLoss: true,
    pauseOnHover: true,
    draggable: true,
    draggablePercent: 0.6,
    showCloseButtonOnHover: false,
    hideProgressBar: false,
    closeButton: "button",
    icon: true,
    rtl: false
};

app.use(Toast, options);

app.mount('#app');
