<template>
    <div 
        class="fixed inset-y-0 left-0 z-40 w-64 bg-white shadow-xl transform transition-transform duration-300 ease-in-out border-r border-gray-100 font-sans"
        :class="isOpen ? 'translate-x-0' : '-translate-x-full'"
    >
        <!-- Sidebar Header -->
        <div class="h-16 flex items-center justify-between px-6 border-b border-gray-100 shrink-0">
            <div v-if="settings?.store_logo" class="flex items-center gap-2">
                <div class="overflow-hidden h-8 flex items-center">
                    <img :src="settings.store_logo" class="h-8 w-auto object-contain" style="filter: drop-shadow(0 100px 0 #5a6c37); transform: translateY(-100px);" :alt="settings.store_name">
                </div>
                <span class="font-bold text-lg text-primary tracking-tight">POS App</span>
            </div>
            <h2 v-else class="font-bold text-lg text-primary tracking-tight">{{ settings?.store_name || 'POS Menu' }}</h2>
            <button @click="$emit('close')" class="p-1 rounded-full hover:bg-gray-100 text-gray-500">
                <XIcon class="w-5 h-5" />
            </button>
        </div>

        <!-- Navigation Links -->
        <div class="flex-1 py-6 px-3 space-y-1 overflow-y-auto w-full">
            <template v-for="item in menuItems" :key="item.path">
                <router-link
                    :to="item.path"
                    @click="$emit('close')"
                    class="flex items-center px-4 py-3 rounded-xl transition-all duration-200 group"
                    :class="[
                        isActive(item.path)
                            ? 'bg-primary text-white shadow-md'
                            : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900'
                    ]"
                >
                    <component :is="item.icon" 
                        class="shrink-0 w-5 h-5 mr-3"
                        :class="[
                            isActive(item.path) ? 'text-white' : 'text-gray-400 group-hover:text-primary'
                        ]"
                    />
                    <span class="font-medium truncate">{{ item.label }}</span>
                </router-link>
            </template>

        </div>
        
        <!-- Footer Info -->
        <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-100 bg-white">
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                        <span class="text-primary font-bold">{{ authStore.user?.name?.charAt(0) || 'C' }}</span>
                    </div>
                    <div>
                        <p class="text-sm font-bold text-gray-800 truncate max-w-[120px]">{{ authStore.user?.name || 'Cashier' }}</p>
                        <p class="text-xs text-green-500 font-medium">Online</p>
                    </div>
                </div>
                <button 
                    @click="$emit('logout')"
                    class="p-2 rounded-lg bg-red-50 text-red-500 hover:bg-red-100 hover:text-red-700 transition"
                    title="Sign Out"
                >
                    <LogOutIcon class="w-5 h-5" />
                </button>
            </div>
        </div>
    </div>
    
    <!-- Backdrop -->
    <div 
        v-if="isOpen" 
        class="fixed inset-0 bg-black/20 backdrop-blur-sm z-30"
        @click="$emit('close')"
    ></div>
</template>

<script setup>
import { useRoute } from 'vue-router';
import { XIcon, MonitorIcon, LayoutGridIcon, ClockIcon, LogOutIcon, CalendarIcon, SettingsIcon, PackageIcon, TagIcon, UsersIcon } from 'lucide-vue-next';
import { useAuthStore } from '../../stores/auth';
import { usePosStore } from '../../stores/pos';
import { computed } from 'vue';

const authStore = useAuthStore();
const posStore = usePosStore();
const settings = computed(() => posStore.settings);

defineProps({
    isOpen: {
        type: Boolean,
        default: false
    }
});

defineEmits(['close', 'logout']);

const route = useRoute();
const isActive = (path) => route.path === path;

const menuItems = [
    { path: '/pos/dashboard', label: 'Dashboard', icon: LayoutGridIcon },
    { path: '/pos', label: 'Cashier', icon: MonitorIcon },
    { path: '/pos/products', label: 'Menu', icon: TagIcon },
    { path: '/pos/history', label: 'Transaction History', icon: ClockIcon },
    { path: '/pos/members', label: 'Members', icon: UsersIcon },
    { path: '/pos/inventory', label: 'Inventory', icon: PackageIcon },
    { path: '/pos/shifts', label: 'Shift History', icon: CalendarIcon },
    { path: '/pos/settings', label: 'Settings', icon: SettingsIcon },
];
</script>
