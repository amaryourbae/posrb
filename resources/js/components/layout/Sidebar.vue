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
        <div class="flex-1 py-6 px-3 space-y-4 overflow-y-auto w-full">
            <template v-for="(group, groupIndex) in filteredMenuItems" :key="groupIndex">
                <div v-if="group.items.length > 0" class="space-y-1">
                    <!-- Group Header -->
                    <div 
                        v-if="!collapsed || mobileOpen"
                        class="px-4 py-2 text-xs font-bold text-gray-400 uppercase tracking-wider flex justify-between items-center cursor-pointer hover:text-gray-600 transition-colors"
                        @click="toggleGroup(group.title)"
                    >
                        <span>{{ group.title }}</span>
                        <ChevronDownIcon 
                            class="w-4 h-4 transition-transform duration-200"
                            :class="{ '-rotate-90': !openGroups[group.title] }"
                        />
                    </div>
                    
                    <!-- Group Items -->
                    <div v-show="collapsed && !mobileOpen || openGroups[group.title]" class="space-y-1">
                        <template v-for="item in group.items" :key="item.path">
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
                </div>
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
    ImagesIcon,
    ScaleIcon,
    SmartphoneIcon,
    TrendingUpIcon,
    ChevronDownIcon,
    FoldersIcon
} from 'lucide-vue-next';

import api from '../../api/axios';
import { ref, onMounted, computed, watch } from 'vue';

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

const isActive = (path) => {
    // Avoid marking parent active when on child route unless exact match,
    // except for dashboard where exact match is required
    if (path === '/admin') {
        return route.path === '/admin';
    }
    return route.path.startsWith(path);
};

const menuStructure = [
    {
        title: 'Core',
        items: [
            { path: '/admin', label: 'Dashboard', icon: LayoutDashboardIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/orders', label: 'Transactions', icon: ClipboardListIcon, roles: ['super_admin', 'store_manager'] },
            { path: '/pos', label: 'POS System', icon: ShoppingBagIcon, roles: ['super_admin', 'cashier'] },
            { path: '/admin/shifts', label: 'Shift History', icon: ClipboardListIcon, roles: ['super_admin', 'store_manager'] },
        ]
    },
    {
        title: 'Catalog',
        items: [
            { path: '/admin/products', label: 'Products', icon: PackageIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/categories', label: 'Categories', icon: FoldersIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/modifiers', label: 'Modifiers', icon: TagsIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/discounts', label: 'Discounts', icon: TagsIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
        ]
    },
    {
        title: 'Inventory',
        items: [
            { path: '/admin/inventory', label: 'Stock Current', icon: WarehouseIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/units', label: 'Units', icon: ScaleIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
            { path: '/admin/suppliers', label: 'Suppliers', icon: TruckIcon, roles: ['super_admin', 'store_manager', 'cashier', 'report'] },
        ]
    },
    {
        title: 'People',
        items: [
            { path: '/admin/customers', label: 'Members', icon: UsersIcon, roles: ['super_admin', 'store_manager', 'cashier'] },
            { path: '/admin/users', label: 'Employees', icon: UsersIcon, roles: ['super_admin', 'store_manager'] },
        ]
    },
    {
        title: 'Reports & Analytics',
        items: [
            { path: '/admin/reports', label: 'Sales Report', icon: PieChartIcon, roles: ['super_admin', 'store_manager', 'report'] },
            { path: '/admin/reports/profit-loss', label: 'Laba Rugi (HPP)', icon: TrendingUpIcon, roles: ['super_admin', 'store_manager', 'report'] },
            { path: '/admin/reports/inventory', label: 'Stock In/Out', icon: WarehouseIcon, roles: ['super_admin', 'store_manager', 'report'] },
        ]
    },
    {
        title: 'System',
        items: [
            { path: '/admin/banners', label: 'Banners', icon: ImagesIcon, roles: ['super_admin'] },
            { path: '/admin/audit-logs', label: 'Audit Logs', icon: ShieldCheckIcon, roles: ['super_admin'] },
            { path: '/admin/settings/updates', label: 'App Updates', icon: SmartphoneIcon, roles: ['super_admin'] },
            { path: '/admin/settings', label: 'Settings', icon: SettingsIcon, roles: ['super_admin'] },
        ]
    }
];

// Reactive state for open/closed groups
const openGroups = ref({
    'Core': true,
    'Catalog': true,
    'Inventory': true,
    'People': false,
    'Reports & Analytics': false,
    'System': false,
});

const toggleGroup = (groupTitle) => {
    openGroups.value[groupTitle] = !openGroups.value[groupTitle];
};

const filteredMenuItems = computed(() => {
    if (!authStore.user || !authStore.user.roles) return [];
    const userRoles = authStore.user.roles.map(r => r.name);
    
    return menuStructure.map(group => {
        const filteredItems = group.items.filter(item => {
            return item.roles.some(role => userRoles.includes(role));
        });
        return { ...group, items: filteredItems };
    }).filter(group => group.items.length > 0);
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

const checkActiveGroup = () => {
    menuStructure.forEach(group => {
        const hasActiveItem = group.items.some(item => isActive(item.path));
        if (hasActiveItem) {
            openGroups.value[group.title] = true;
        }
    });
};

watch(() => route.path, () => {
    checkActiveGroup();
});

onMounted(() => {
    fetchSettings();
    checkActiveGroup();
});
</script>
