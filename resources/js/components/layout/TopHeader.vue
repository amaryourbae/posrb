<template>
    <div
        class="h-16 bg-white border-b border-gray-100 flex items-center justify-between px-4 md:px-8 sticky top-0 z-10 transition-shadow duration-300"
        :class="{ 'shadow-sm': scrolled }"
    >
        <!-- Left Side: Toggle & Search -->
        <div class="flex items-center space-x-2 md:space-x-4 flex-1">
            <button @click="$emit('toggle-sidebar')" class="p-2 rounded-lg hover:bg-gray-100 text-gray-500 hover:text-primary transition-colors">
                <MenuIcon class="w-6 h-6" />
            </button>
            <div class="w-full max-w-sm hidden md:block">
                <div class="relative">
                    <SearchIcon
                        class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5"
                    />
                    <input
                        type="text"
                        placeholder="Search anything..."
                        class="w-full pl-10 pr-4 py-2 bg-gray-50 border-none rounded-xl text-sm focus:ring-2 focus:ring-primary/20 focus:bg-white transition-all duration-200"
                    />
                </div>
            </div>
             <!-- Mobile Search Icon (Placeholder for now) -->
             <button class="md:hidden p-2 text-gray-400 hover:text-primary">
                <SearchIcon class="w-5 h-5"/>
             </button>
        </div>

        <!-- Right Side -->
        <div class="flex items-center space-x-2 md:space-x-6 shrink-0">
            <button
                class="relative p-2 text-gray-400 hover:text-primary hover:bg-green-50 rounded-full transition-colors"
            >
                <BellIcon class="w-5 h-5" />
                <span
                    class="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border-2 border-white"
                ></span>
            </button>

            <div
                class="flex items-center space-x-3 pl-2 md:pl-6 md:border-l border-gray-100"
            >
                <div class="text-right hidden md:block">
                    <div class="text-sm font-bold text-gray-800">
                        {{ authStore.user?.name || "User" }}
                    </div>
                    <div class="text-xs text-gray-500 capitalize">{{ userRoleLabel }}</div>
                </div>
                <div
                    class="h-8 w-8 md:h-10 md:w-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold border-2 border-white shadow-sm ring-2 ring-primary/5"
                >
                    {{ (authStore.user?.name || "U")[0] }}
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from "vue";
import { SearchIcon, BellIcon, MenuIcon } from "lucide-vue-next";
const emit = defineEmits(['toggle-sidebar']);
import { useAuthStore } from "../../stores/auth";

const authStore = useAuthStore();
const scrolled = ref(false);

const userRoleLabel = computed(() => {
    const roles = authStore.user?.roles;
    if (roles && roles.length > 0) {
        return roles[0].name.replace(/_/g, " ");
    }
    return "Staff";
});

const handleScroll = () => {
    scrolled.value = window.scrollY > 10;
};

onMounted(() => window.addEventListener("scroll", handleScroll));
onUnmounted(() => window.removeEventListener("scroll", handleScroll));
</script>
