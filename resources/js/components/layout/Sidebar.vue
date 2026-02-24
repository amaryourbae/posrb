<template>
    <div
        class="h-screen bg-white border-r border-gray-100 flex flex-col fixed left-0 top-0 transition-transform md:transition-all duration-300 z-30"
        :class="[
            collapsed ? 'md:w-20 md:items-center' : 'md:w-64',
            mobileOpen ? 'translate-x-0 w-64' : '-translate-x-full md:translate-x-0'
        ]"
    >
        <!-- Logo -->
        <div class="h-16 flex items-center border-b border-gray-100 shrink-0" :class="collapsed ? 'md:justify-center md:px-0 px-6' : 'px-6'">
            <template v-if="!collapsed || mobileOpen">
                 <div v-if="logo" class="overflow-hidden h-12 w-full flex items-center justify-start">
                    <img :src="logo" class="h-12 w-auto object-contain" style="filter: drop-shadow(0 100px 0 #5a6c37); transform: translateY(-100px);" alt="Logo">
                 </div>
                 <span
                    v-else
                    class="text-xl font-bold bg-clip-text text-transparent bg-linear-to-r from-primary to-green-700 truncate"
                >
                    {{ storeName || 'Ruang Bincang' }}
                </span>
            </template>
            <span v-else class="text-xl font-bold text-primary flex justify-center w-full">
                RB
            </span>
            
            <!-- Close button on mobile -->
            <button @click="$emit('close-mobile')" class="ml-auto md:hidden text-gray-400 hover:text-gray-600">
                <XIcon class="w-6 h-6" />
            </button>
        </div>

        <!-- Navigation -->
        <div class="flex-1 py-6 px-3 space-y-1 overflow-y-auto w-full">
            <template v-for="item in filteredMenuItems" :key="item.path">
                <router-link
                    :to="item.path"
                    @click="$emit('close-mobile')"
                    class="flex items-center px-4 py-3 rounded-xl transition-all duration-200 group"
                    :class="[
                        isActive(item.path)
                            ? 'bg-primary text-white shadow-md'
                            : 'text-gray-500 hover:bg-gray-50 hover:text-gray-900',
                        collapsed && !mobileOpen ? 'md:justify-center md:px-2' : ''
                    ]"
                    :title="collapsed ? item.label : ''"
                >
                    <component :is="item.icon" 
                        class="shrink-0"
                        :class="[
                            isActive(item.path) ? 'text-white' : 'text-gray-400 group-hover:text-primary',
                            collapsed && !mobileOpen ? 'w-6 h-6' : 'w-5 h-5 mr-3'
                        ]"
                    />
                    <span v-if="!collapsed || mobileOpen" class="font-medium truncate">{{ item.label }}</span>
                </router-link>
            </template>
        </div>

        <!-- Logout -->
        <div class="p-4 border-t border-gray-100 w-full shrink-0">
            <button
                @click="handleLogout"
                class="flex items-center px-4 py-3 w-full rounded-xl text-gray-500 hover:bg-red-50 hover:text-red-500 transition-colors"
                :class="collapsed && !mobileOpen ? 'md:justify-center' : ''"
                :title="collapsed ? 'Logout' : ''"
            >
                <LogOutIcon class="shrink-0" :class="collapsed && !mobileOpen ? 'w-6 h-6' : 'w-5 h-5 mr-3'" />
                <span v-if="!collapsed || mobileOpen" class="font-medium">Logout</span>
            </button>
        </div>
    </div>
</template>

<script setup>
import { useRoute } from "vue-router";
import { useAuthStore } from "../../stores/auth";
import {
    LayoutDashboardIcon,
    ClipboardListIcon,
    ShoppingBagIcon,
    TagsIcon,
    PackageIcon,
    PieChartIcon,
    SettingsIcon,
    LogOutIcon,
    WarehouseIcon,
    UsersIcon,
    TruckIcon,
    ShieldCheckIcon,
    XIcon,
    ImageIcon
} from 'lucide-vue-next';

import api from '../../api/axios';
import { ref, onMounted, computed } from 'vue';

const route = useRoute();
const authStore = useAuthStore();
const logo = ref(localStorage.getItem('admin_store_logo') || null);
const storeName = ref(localStorage.getItem('admin_store_name') || '');

defineProps({
    collapsed: {
        type: Boolean,
        default: false
    },
    mobileOpen: {
        type: Boolean,
        default: false
    }
});

const isActive = (path) => route.path === path;

const menuItems = [
    { path: '/admin', label: 'Dashboard', icon: LayoutDashboardIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/orders', label: 'Transactions', icon: ClipboardListIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/pos', label: 'POS System', icon: ShoppingBagIcon, roles: ['super_admin', 'store_manager', 'cashier'] },
    { path: '/admin/categories', label: 'Categories', icon: TagsIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/products', label: 'Products', icon: PackageIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/modifiers', label: 'Modifiers', icon: TagsIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/inventory', label: 'Inventory', icon: WarehouseIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/suppliers', label: 'Suppliers', icon: TruckIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/customers', label: 'Members', icon: UsersIcon, roles: ['super_admin', 'store_manager', 'cashier'] },
    { path: '/admin/users', label: 'Employees', icon: UsersIcon, roles: ['super_admin'] },
    { path: '/admin/shifts', label: 'Shift History', icon: ClipboardListIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/discounts', label: 'Discounts', icon: TagsIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/banners', label: 'Banners', icon: ImageIcon, roles: ['super_admin'] },
    { path: '/admin/reports', label: 'Reports', icon: PieChartIcon, roles: ['super_admin', 'store_manager'] },
    { path: '/admin/audit-logs', label: 'Audit Logs', icon: ShieldCheckIcon, roles: ['super_admin'] },
    { path: '/admin/settings', label: 'Settings', icon: SettingsIcon, roles: ['super_admin'] },
];

const filteredMenuItems = computed(() => {
    if (!authStore.user || !authStore.user.roles) return [];
    const userRoles = authStore.user.roles.map(r => r.name);
    
    return menuItems.filter(item => {
        return item.roles.some(role => userRoles.includes(role));
    });
});

const fetchSettings = async () => {
    try {
        const response = await api.get('/settings');
        const resData = response.data?.data || response.data || {};
        
        if (resData.store_logo) {
            logo.value = resData.store_logo;
            localStorage.setItem('admin_store_logo', resData.store_logo);
        }
        if (resData.store_name) {
             storeName.value = resData.store_name;
             localStorage.setItem('admin_store_name', resData.store_name);
        }
    } catch(e) {}
};

const handleLogout = async () => {
    await authStore.logout();
    window.location.href = "/login";
};

onMounted(() => {
    fetchSettings();
});
</script>
