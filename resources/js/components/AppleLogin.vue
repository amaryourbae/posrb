<template>
  <div @click="initAppleLogin" class="cursor-pointer h-full w-full">
    <slot></slot>
  </div>
</template>

<script setup>
import { onMounted } from 'vue';

const props = defineProps({
  clientId: {
    type: String,
    required: true
  },
  redirectURI: {
    type: String,
    required: true
  },
  scope: {
    type: String,
    default: 'name email'
  },
  state: {
    type: String,
    default: 'apple_login_state'
  }
});

const emit = defineEmits(['success', 'error']);

onMounted(() => {
  // Load Apple script dynamically if not present
  if (!document.getElementById('apple-auth-script')) {
    const script = document.createElement('script');
    script.id = 'apple-auth-script';
    script.src = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js';
    document.head.appendChild(script);
    
    script.onload = () => {
      initAppleJS();
    };
  } else {
    initAppleJS();
  }
});

const initAppleJS = () => {
    if (window.AppleID) {
        window.AppleID.auth.init({
            clientId : props.clientId,
            scope : props.scope,
            redirectURI : props.redirectURI,
            state : props.state,
            usePopup : true // Recommended for SPA
        });
    }
}

const initAppleLogin = async () => {
  try {
    const data = await window.AppleID.auth.signIn();
    // data.authorization.id_token contains the JWT from Apple
    // data.user contains name/email (ONLY ON FIRST LOGIN)
    emit('success', data);
  } catch (error) {
    emit('error', error);
  }
};
</script>
