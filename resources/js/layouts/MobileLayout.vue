<template>
    <div class="h-screen w-full font-sans text-slate-800 flex justify-center bg-gray-100 overflow-hidden">
        <div class="w-full max-w-md bg-white h-full shadow-2xl relative flex flex-col">
            <!-- Header -->
            <header v-if="showHeader" class="sticky top-0 z-20 bg-white/95 backdrop-blur-sm border-b border-gray-100 px-5 py-3 flex items-center justify-between">
                <!-- Left: Logo -->
                <div class="flex items-center gap-2.5">
                    <div class="w-9 h-9 bg-primary text-white rounded-xl flex items-center justify-center shadow-lg shadow-primary/25">
                         <img v-if="settings?.store_logo" :src="settings.store_logo" class="w-5 h-5 object-contain filter brightness-0 invert" />
                         <CoffeeIcon v-else class="w-5 h-5" />
                    </div>
                    <div class="flex flex-col leading-none">
                         <template v-if="settings?.store_name">
                             <h1 class="text-sm font-extrabold text-primary tracking-tight">{{ settings.store_name.split(' ')[0] }}</h1>
                             <h1 class="text-sm font-extrabold text-slate-900 tracking-tight">{{ settings.store_name.split(' ').slice(1).join(' ') || 'Coffee' }}</h1>
                         </template>
                         <template v-else>
                            <h1 class="text-sm font-extrabold text-primary tracking-tight">Ruang</h1>
                            <h1 class="text-sm font-extrabold text-slate-900 tracking-tight">Bincang</h1>
                         </template>
                    </div>
                </div>

                <!-- Right: Bell & Avatar -->
                <div class="flex items-center gap-3">
                    <!-- Notification Bell -->
                    <button class="relative w-9 h-9 flex items-center justify-center rounded-full text-slate-500 hover:bg-slate-50 transition-colors">
                        <BellIcon class="w-5 h-5" />
                        <!-- Red Dot Mockup -->
                        <span class="absolute top-2 right-2.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
                    </button>

                    <!-- Avatar -->
                    <router-link 
                        :to="member ? '/app/profile' : '/app/login'"
                        class="relative w-9 h-9 rounded-full overflow-hidden border border-gray-100 shadow-sm active:scale-95 transition-transform"
                    >
                        <img 
                            v-if="member && member.avatar_url" 
                            :src="member.avatar_url" 
                            class="w-full h-full object-cover" 
                            alt="Avatar"
                        />
                        <div v-else class="w-full h-full bg-slate-100 flex items-center justify-center text-slate-400">
                            <UserIcon class="w-5 h-5" />
                        </div>
                    </router-link>
                </div>
            </header>

            <!-- Custom Header Slot -->
            <slot name="header-custom"></slot>

            <!-- Main Content -->
            <main class="flex-1 overflow-y-auto no-scrollbar" :class="{'pb-24': showFooter}">
                <slot />
            </main>

            <!-- Bottom Navigation -->
            <nav v-if="showFooter" class="sticky bottom-0 z-30 w-full border-t border-gray-100 bg-white pb-safe">
                <div class="flex h-16 w-full items-center justify-around">
                    <router-link 
                        to="/app" 
                        class="flex flex-col items-center gap-1 p-2 transition-colors group"
                        active-class="text-primary"
                        :class="$route.path === '/app' ? 'text-primary' : 'text-gray-400 hover:text-gray-600'"
                    >
                        <HomeIcon class="w-6 h-6 transition-all group-active:scale-90" :class="$route.path === '/app' ? 'fill-current' : ''" />
                        <span class="text-[10px] font-bold">Home</span>
                    </router-link>
                    
                    <router-link 
                        to="/app/order" 
                        class="flex flex-col items-center gap-1 p-2 transition-colors text-gray-400 hover:text-gray-600 group"
                        active-class="text-primary"
                    >
                        <CoffeeIcon class="w-6 h-6 transition-all group-active:scale-90" />
                        <span class="text-[10px] font-bold">Order</span>
                    </router-link>

                    <router-link 
                        to="/app/promo" 
                        class="flex flex-col items-center gap-1 p-2 transition-colors text-gray-400 hover:text-gray-600 group"
                        active-class="text-primary"
                    >
                        <TicketIcon class="w-6 h-6 transition-all group-active:scale-90" />
                        <span class="text-[10px] font-bold">Promo</span>
                    </router-link>

                     <router-link 
                        :to="member ? '/app/profile' : '/app/login'"
                        class="flex flex-col items-center gap-1 p-2 transition-colors text-gray-400 hover:text-gray-600 group"
                        active-class="text-primary"
                    >
                        <UserIcon class="w-6 h-6 transition-all group-active:scale-90" :class="$route.path.startsWith('/app/profile') ? 'fill-current' : ''" />
                        <span class="text-[10px] font-bold text-center">Profile</span>
                    </router-link>
                </div>
            </nav>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { useMemberAuthStore } from '../stores/memberAuth';
import { useCustomerStore } from '../stores/customer';
import { 
    HomeIcon, CoffeeIcon, TicketIcon, UserIcon, BellIcon 
} from 'lucide-vue-next';

// Access Member Store
const authStore = useMemberAuthStore();
const customerStore = useCustomerStore();
const member = computed(() => authStore.currentUser);
const settings = computed(() => customerStore.settings);

const props = defineProps({
    showHeader: {
        type: Boolean,
        default: true
    },
    showFooter: {
        type: Boolean,
        default: true
    }
});
</script>

<style scoped>
.pb-safe {
    padding-bottom: env(safe-area-inset-bottom);
}
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
