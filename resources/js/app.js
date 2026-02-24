import { createApp } from 'vue';
import { createPinia } from 'pinia';
import router from './router';
import App from './App.vue';
import './bootstrap'; // Keep boostrap for Axios default headers if needed, though we made our own axios instance. 
// Standard in Laravel is to keep bootstrap.js which loads lodash and sets axios headers.
// However, our custom axios instance handles headers. We can keep it or remove it.
// Let's keep it to be safe for now, or just remove it if we rely purely on our axios.js
// Actually, standard bootstrap.js sets window.axios. Let's keep it.

const app = createApp(App);

app.use(createPinia());
app.use(router);

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
