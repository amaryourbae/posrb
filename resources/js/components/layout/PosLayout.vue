<template>
    <div class="bg-gray-50 min-h-screen font-sans text-slate-800">
        <!-- Navigation Sidebar -->
        <PosSidebar :is-open="sidebarOpen" @close="sidebarOpen = false" @logout="handleLogout" />

        <!-- Main Container -->
        <div class="flex flex-col h-screen overflow-hidden">
            <!-- Header -->
            <header class="bg-white px-4 md:px-6 pb-4 pt-[calc(1rem+env(safe-area-inset-top))] flex items-center justify-between shadow-sm z-10 shrink-0">
                <div class="flex items-center gap-4">
                    <!-- Toggle Button -->
                    <button 
                        @click="sidebarOpen = !sidebarOpen"
                        class="p-2 -ml-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full transition"
                        title="Menu"
                    >
                        <MenuIcon class="w-6 h-6" />
                    </button>
                    
                    <!-- Logo Area -->
                    <div class="flex items-center gap-2">
                        <template v-if="!posStore.settings.store_name">
                             <div class="w-8 h-8 rounded-full bg-gray-200 animate-pulse"></div>
                             <div class="hidden sm:block space-y-1">
                                 <div class="h-4 w-32 bg-gray-200 rounded animate-pulse"></div>
                                 <div class="h-2 w-16 bg-gray-200 rounded animate-pulse"></div>
                             </div>
                        </template>
                        <template v-else>
                             <div v-if="posStore.settings.store_logo" class="overflow-hidden h-10 flex items-center">
                                <img :src="posStore.settings.store_logo" class="h-10 w-auto object-contain" style="filter: drop-shadow(0 100px 0 #5a6c37); transform: translateY(-100px);" alt="Logo" />
                             </div>
                             <div v-else class="flex items-center gap-2">
                                <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white font-bold italic shadow-sm">R</div>
                                <div class="leading-tight hidden sm:block">
                                     <h1 class="text-lg font-bold tracking-tight text-primary">{{ posStore.settings.store_name || 'POS System' }}</h1>
                                     <p class="text-[0.6rem] uppercase tracking-widest text-slate-400 font-bold">Cashier Point</p>
                                </div>
                             </div>
                        </template>
                    </div>
                </div>

                <!-- Right Actions -->
                <div class="flex items-center gap-3">
                    <div class="relative">
                        <button 
                            @click="toggleNotificationDropdown"
                            class="p-2 relative text-gray-400 hover:text-gray-600 transition"
                        >
                             <BellIcon class="w-5 h-5" />
                             <div v-if="pendingCount > 0" class="w-4 h-4 bg-red-500 text-white text-[10px] font-bold flex items-center justify-center rounded-full absolute top-1 right-1 border-2 border-white animate-pulse">
                                {{ pendingCount }}
                             </div>
                        </button>

                        <!-- Notification Dropdown -->
                        <div v-if="notificationDropdownOpen" class="absolute right-0 mt-2 w-64 bg-white rounded-xl shadow-lg border border-gray-100 py-2 z-50">
                            <div class="px-4 py-2 border-b border-gray-50 flex justify-between items-center">
                                <h3 class="font-bold text-sm text-gray-800">Notifications</h3>
                                <button @click="notificationDropdownOpen = false" class="text-gray-400 hover:text-gray-600">
                                    <XIcon class="w-4 h-4" />
                                </button>
                            </div>
                            <div v-if="pendingCount === 0" class="px-4 py-6 text-center text-sm text-gray-400">
                                No new orders
                            </div>
                            <div v-else class="py-2">
                                <div class="px-4 py-2 hover:bg-green-50 cursor-pointer transition" @click="$emit('open-pending')">
                                    <p class="text-sm font-bold text-gray-800">New Pending Orders</p>
                                    <p class="text-xs text-green-600">{{ pendingCount }} orders waiting for action</p>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Backdrop -->
                        <div v-if="notificationDropdownOpen" class="fixed inset-0 z-40" @click="notificationDropdownOpen = false"></div>
                    </div>
                    
                    <div class="h-8 w-px bg-gray-200 mx-1 hidden md:block"></div>

                    <!-- User Dropdown -->
                    <div class="relative">
                        <div 
                            @click="toggleDropdown"
                            class="flex items-center gap-2 cursor-pointer hover:bg-gray-50 p-1.5 rounded-lg transition"
                        >
                             <img :src="authStore.user?.avatar_url || `https://ui-avatars.com/api/?name=${authStore.user?.name || 'User'}&background=random`" class="w-8 h-8 rounded-full border border-gray-200" />
                             <span class="text-sm font-medium hidden md:block text-slate-700">{{ authStore.user?.name || 'Guest' }}</span>
                             <ChevronDownIcon class="w-4 h-4 text-gray-400 hidden md:block" />
                        </div>
                        
                        <!-- Dropdown Menu -->
                        <div v-if="userDropdownOpen" class="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-gray-100 py-1 z-50">
                            <button 
                                @click="handleLogout"
                                class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 hover:text-red-700 flex items-center gap-2"
                            >
                                <LogOutIcon class="w-4 h-4" />
                                Logout
                            </button>
                        </div>
                        
                        <!-- Backdrop for dropdown -->
                        <div v-if="userDropdownOpen" class="fixed inset-0 z-40" @click="userDropdownOpen = false"></div>
                    </div>
                </div>
            </header>

            <!-- Page Content -->
            <main class="flex-1 overflow-hidden relative">
                <slot />
            </main>
        </div>

        <!-- Shared Shift Modal -->
        <ShiftModal 
            :is-open="shiftModalOpen"
            :mode="shiftModalMode"
            :loading="shiftLoading"
            :expected-cash="posStore.shift?.expected_cash"
            @close="shiftModalOpen = false"
            @submit="handleShiftSubmit"
        />

        <ShiftReceipt 
            v-if="printedShift" 
            :shift="printedShift" 
            :store-name="posStore.settings.store_name"
        />
    </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';
import { MenuIcon, BellIcon, ChevronDownIcon, LogOutIcon, XIcon } from 'lucide-vue-next';
import PosSidebar from './PosSidebar.vue';
import { usePosStore } from '../../stores/pos';
import { useAuthStore } from '../../stores/auth';
import ShiftModal from '../pos/ShiftModal.vue';
import ShiftReceipt from '../pos/ShiftReceipt.vue';

const sidebarOpen = ref(false);
const posStore = usePosStore();
const authStore = useAuthStore();

// Dropdown State
const userDropdownOpen = ref(false);
const shiftModalOpen = ref(false);
const shiftModalMode = ref('end');
const shiftLoading = ref(false);

const toggleDropdown = () => {
    userDropdownOpen.value = !userDropdownOpen.value;
};

const handleLogout = async () => {
    // Check for open shift (refresh data to get latest stats)
    await posStore.fetchCurrentShift();
    
    if (posStore.shift) {
        shiftModalMode.value = 'end';
        shiftModalOpen.value = true;
        return;
    }
    
    // Proceed with logout
    await authStore.logout();
    window.location.href = '/login';
};


const printedShift = ref(null);

const handleShiftSubmit = async (data) => {
    shiftLoading.value = true;
    try {
        if (shiftModalMode.value === 'end') {
            const result = await posStore.endShift({
                actual_cash: data.amount,
                note: data.note
            });
            
            shiftModalOpen.value = false;
            
            // Print Receipt
            if (result) {
                printedShift.value = result;
                await nextTick();
                window.print();
                await new Promise(resolve => setTimeout(resolve, 500)); // Small delay
                printedShift.value = null;
            }

            // After ending shift, continue logout
            await handleLogout();
        } else {
             // Handle Open Shift
              await posStore.startShift(data.amount);
              shiftModalOpen.value = false;
        }
    } catch (e) {
        alert(e.message || 'Failed to update shift');
    } finally {
        shiftLoading.value = false;
    }
};

// Notification Dropdown State
const notificationDropdownOpen = ref(false);
const pendingCount = computed(() => posStore.pendingOrderCount);

const toggleNotificationDropdown = () => {
    notificationDropdownOpen.value = !notificationDropdownOpen.value;
};

// ... (keep existing methods)

onMounted(async () => {
    // Ensure settings are loaded for the header
    if (!posStore.settings.store_name) {
        posStore.fetchSettings();
    }
    // Fetch current shift status on load
    await posStore.fetchCurrentShift();

    // Start Polling for Notifications
    posStore.startPollingPendingOrders(5000);
});

import { onUnmounted } from 'vue';
onUnmounted(() => {
    posStore.stopPollingPendingOrders();
});
</script>
