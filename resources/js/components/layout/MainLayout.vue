<template>
    <div class="min-h-screen bg-gray-50 font-sans text-slate-800">
        <!-- Mobile Backdrop -->
        <div 
            v-if="isMobileSidebarOpen" 
            class="fixed inset-0 bg-black/50 z-20 md:hidden backdrop-blur-sm"
            @click="closeMobileSidebar"
        ></div>

        <Sidebar 
            :collapsed="isDesktopCollapsed" 
            :mobile-open="isMobileSidebarOpen"
            @close-mobile="closeMobileSidebar"
        />

        <div 
            class="flex flex-col min-h-screen transition-all duration-300" 
            :class="[
                isDesktopCollapsed ? 'md:ml-20' : 'md:ml-64',
                'ml-0'
            ]"
        >
            <TopHeader @toggle-sidebar="toggleSidebar" />
            <main class="flex-1 p-4 md:p-8 overflow-y-auto w-full max-w-[100vw] overflow-x-hidden">
                <div v-if="loading" class="animate-pulse space-y-8">
                    <!-- Page Header Skeleton -->
                    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                        <div class="space-y-3 w-full md:w-1/2">
                            <div class="h-8 bg-gray-200 rounded-lg w-1/3"></div>
                            <div class="h-4 bg-gray-200 rounded w-1/4"></div>
                        </div>
                        <div class="h-10 bg-gray-200 rounded-lg w-32"></div>
                    </div>

                    <!-- Cards Skeleton -->
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div v-for="i in 3" :key="i" class="h-32 bg-white rounded-xl border border-gray-100 shadow-sm p-6 space-y-3">
                            <div class="h-4 bg-gray-100 rounded w-1/2"></div>
                            <div class="h-8 bg-gray-100 rounded w-1/3"></div>
                        </div>
                    </div>

                    <!-- Main Content Skeleton -->
                    <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-6 space-y-4 h-96">
                        <div class="flex flex-col md:flex-row items-center space-y-4 md:space-y-0 md:space-x-4 mb-6">
                             <div class="h-10 w-full md:w-64 bg-gray-100 rounded-lg"></div>
                             <div class="h-10 w-32 bg-gray-100 rounded-lg md:ml-auto"></div>
                        </div>
                        <div class="space-y-4">
                            <div v-for="k in 5" :key="k" class="h-12 bg-gray-50 rounded-lg w-full"></div>
                        </div>
                    </div>
                </div>
                <slot v-else />
            </main>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import Sidebar from "./Sidebar.vue";
import TopHeader from "./TopHeader.vue";

defineProps({
    loading: {
        type: Boolean,
        default: false
    }
});

const isDesktopCollapsed = ref(false);
const isMobileSidebarOpen = ref(false);
const isMobile = ref(false);

const checkIsMobile = () => {
    isMobile.value = window.innerWidth < 768;
    if (!isMobile.value) {
        isMobileSidebarOpen.value = false;
    }
};

const toggleSidebar = () => {
    if (isMobile.value) {
        isMobileSidebarOpen.value = !isMobileSidebarOpen.value;
    } else {
        isDesktopCollapsed.value = !isDesktopCollapsed.value;
    }
};

const closeMobileSidebar = () => {
    if (isMobile.value) {
        isMobileSidebarOpen.value = false;
    }
};

onMounted(() => {
    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);
});

onUnmounted(() => {
    window.removeEventListener('resize', checkIsMobile);
});
</script>
