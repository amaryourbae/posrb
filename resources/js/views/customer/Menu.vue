<template>
    <div class="min-h-screen flex justify-center bg-gray-100 font-sans">
        <div class="w-full max-w-md bg-white min-h-screen shadow-2xl relative flex flex-col">
            <!-- Header (Logo/Search) -->
             <div class="sticky top-0 z-20 bg-white/95 backdrop-blur-md shadow-sm">
                <!-- Top Bar -->
                <div class="flex items-center px-4 py-3 justify-between border-b border-gray-50">
                     <router-link to="/app" class="text-gray-900 flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                        <ChevronLeftIcon class="w-6 h-6" />
                    </router-link>
                     <h2 class="text-slate-800 text-lg font-bold leading-tight tracking-tight">Menu</h2>
                     <button class="flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors text-gray-900">
                        <SearchIcon class="w-6 h-6" />
                    </button>
                </div>
                <!-- Order Type Header -->
                <div class="px-4 pb-4 pt-2">
                    <div class="mb-4">
                        <h1 class="text-2xl font-black text-slate-900 tracking-tight uppercase">{{ store.orderType === 'dine_in' ? 'DINE IN' : 'PICK UP' }}</h1>
                        <p class="text-sm text-gray-500 font-medium">
                            {{ store.orderType === 'dine_in' ? 'Eat comfortably at our place' : 'Pick Up In-Store Without Waiting In Line' }}
                        </p>
                    </div>

                    <!-- Location Card -->
                    <div class="bg-primary rounded-xl p-5 flex items-center justify-between text-white relative overflow-hidden shadow-lg shadow-primary/20">
                         <!-- Decorative circles -->
                         <div class="absolute -right-4 -top-4 w-20 h-20 bg-white/10 rounded-full"></div>
                         <div class="absolute right-10 -bottom-10 w-24 h-24 bg-white/5 rounded-full"></div>

                         <div class="z-10 flex-1 pr-4">
                             <h3 class="font-bold text-base leading-tight">{{ store.settings?.store_name || 'Ruang Bincang' }}</h3>
                             <p class="text-xs text-white/90 mt-1 flex items-center gap-1 font-medium">
                                <MapPinIcon class="w-3 h-3" />
                                {{ store.settings?.store_address ? store.settings.store_address.substring(0, 30) + '...' : 'Location' }}
                             </p>
                         </div>
                         <a 
                            v-if="store.settings?.store_maps_link"
                            :href="store.settings.store_maps_link" 
                            target="_blank"
                            class="z-10 bg-white/20 backdrop-blur-sm text-white border border-white/30 text-[10px] font-bold px-3 py-2 rounded-xl flex items-center gap-1 hover:bg-white/30 transition-colors shadow-sm"
                         >
                            View Maps
                            <MapPinIcon class="w-3 h-3" />
                         </a>
                    </div>
                </div>

                <!-- Tabs (Anchors) -->
                <div class="flex gap-3 px-4 py-3 overflow-x-auto no-scrollbar scroll-smooth items-center">
                    <button 
                        v-if="!showFavorites"
                        @click="scrollToSection('recommended')"
                        class="flex h-9 shrink-0 items-center justify-center px-4 rounded-full transition-all active:scale-95 border"
                        :class="activeSection === 'recommended' ? 'bg-[#5a6c37] text-white border-[#5a6c37] shadow-md shadow-green-900/10' : 'bg-white border-gray-200 text-gray-500 hover:bg-gray-50'"
                    >
                         <ThumbsUpIcon class="w-4 h-4" :class="activeSection === 'recommended' ? 'text-white' : 'text-gray-400'" />
                         <span class="ml-1.5 font-bold text-sm">Rekomendasi</span>
                    </button>
                    <!-- Favorites Tab (replaces recommended when active) -->
                    <button 
                        v-else
                        @click="activeSection = 'favorites'"
                        class="flex h-9 shrink-0 items-center justify-center px-4 rounded-full transition-all active:scale-95 border bg-[#5a6c37] text-white border-[#5a6c37] shadow-md shadow-green-900/10"
                    >
                         <HeartIcon class="w-4 h-4 text-red-500 fill-current" />
                         <span class="ml-1.5 font-bold text-sm">My Favorite</span>
                    </button>
                    <button 
                         v-for="cat in nonEmptyCategories" 
                         :key="cat.id"
                         @click="scrollToSection(cat.slug)"
                         class="flex h-9 shrink-0 items-center justify-center px-5 rounded-full transition-all active:scale-95 border"
                         :class="activeSection === cat.slug ? 'bg-[#5a6c37] text-white border-[#5a6c37] shadow-md shadow-green-900/10' : 'bg-white border-gray-200 text-gray-500 hover:bg-gray-50'"
                    >
                        <span class="font-bold text-sm">{{ cat.name }}</span>
                    </button>
                </div>
            </div>

            <!-- Content -->
            <div class="flex-1 overflow-y-auto pb-32 no-scrollbar scroll-smooth bg-gray-50/50" id="menu-container">
                
                <!-- Recommended Section -->
                <section v-if="!showFavorites" id="sec-recommended" class="pt-6 px-4 mb-2 scroll-mt-36">
                    <div class="flex justify-between items-end mb-4 px-1">
                        <h3 class="text-xl font-bold text-slate-800 tracking-tight">Rekomendasi</h3>
                        <router-link to="/app/order?filter=recommended" class="text-xs font-bold text-[#5a6c37] mb-1">Lihat Semua</router-link>
                    </div>
                    <!-- Horizontal Scroll -->
                    <div class="flex gap-4 overflow-x-auto no-scrollbar pb-6 -mx-4 px-4 snap-x">
                        <div v-if="loadingRecommended" class="flex gap-4">
                             <div v-for="i in 3" :key="i" class="w-[280px] h-[120px] bg-gray-200 rounded-2xl animate-pulse shrink-0"></div>
                        </div>
                        <div 
                            v-else
                            v-for="item in recommendedItems" 
                            :key="item.id" 
                            @click="router.push(`/app/product/${item.id}`)"
                            class="snap-center shrink-0 w-[300px] bg-white p-3 rounded-2xl shadow-sm border border-gray-100 flex items-start gap-3 active:scale-[0.98] transition-transform relative cursor-pointer"
                        >
                            <div class="w-24 h-24 rounded-xl bg-gray-100 overflow-hidden shrink-0">
                                <img :src="item.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                            </div>
                            <div class="flex-1 min-w-0 py-1">
                                <h4 class="font-bold text-slate-800 text-base leading-tight line-clamp-2 mb-1">{{ item.name }}</h4>
                                <p class="text-xs text-gray-500 line-clamp-2 mb-2 leading-relaxed">{{ item.description }}</p>
                                <div class="flex justify-between items-end">
                                    <p class="font-bold text-slate-900">Rp {{ formatNumber(item.price) }}</p>
                                    <button class="w-7 h-7 rounded-full bg-[#5a6c37] text-white flex items-center justify-center shadow-md shadow-green-900/20 active:scale-90 transition-transform">
                                        <PlusIcon class="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                            <button @click.stop="toggleFavorite(item)" class="absolute top-2 right-2 transition-colors" :class="isFavorite(item) ? 'text-red-500' : 'text-gray-300 hover:text-red-500'">
                                <HeartIcon class="w-4 h-4" :class="{ 'fill-current': isFavorite(item) }" />
                            </button>
                        </div>
                    </div>
                </section>

                <!-- Favorites Section (Conditionally replaces Recommended) -->
                <section v-else id="sec-favorites" class="pt-6 px-4 mb-2 scroll-mt-36">
                    <div class="flex justify-between items-end mb-4 px-1">
                        <h3 class="text-xl font-bold text-slate-800 tracking-tight">My Favorite</h3>
                    </div>
                    <!-- Horizontal Scroll -->
                    <div class="flex gap-4 overflow-x-auto no-scrollbar pb-6 -mx-4 px-4 snap-x">
                        <div 
                            v-for="item in favorites" 
                            :key="item.id" 
                            @click="router.push(`/app/product/${item.id}`)"
                            class="snap-center shrink-0 w-[300px] bg-white p-3 rounded-2xl shadow-sm border border-gray-100 flex items-start gap-3 active:scale-[0.98] transition-transform relative cursor-pointer"
                        >
                            <div class="w-24 h-24 rounded-xl bg-gray-100 overflow-hidden shrink-0">
                                <img :src="item.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                            </div>
                            <div class="flex-1 min-w-0 py-1">
                                <h4 class="font-bold text-slate-800 text-base leading-tight line-clamp-2 mb-1">{{ item.name }}</h4>
                                <p class="text-xs text-gray-500 line-clamp-2 mb-2 leading-relaxed">{{ item.description }}</p>
                                <div class="flex justify-between items-end">
                                    <p class="font-bold text-slate-900">Rp {{ formatNumber(item.price) }}</p>
                                    <button class="w-7 h-7 rounded-full bg-[#5a6c37] text-white flex items-center justify-center shadow-md shadow-green-900/20 active:scale-90 transition-transform">
                                        <PlusIcon class="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                            <button @click.stop="toggleFavorite(item)" class="absolute top-2 right-2 text-red-500 transition-colors">
                                <HeartIcon class="w-4 h-4 fill-current" />
                            </button>
                        </div>
                    </div>
                </section>

                <div class="h-2 bg-gray-100/50 w-full mb-6"></div>

                <!-- Categories Loops -->
                <section 
                    v-for="cat in groupedProducts" 
                    :key="cat.id" 
                    :id="'sec-' + cat.slug"
                    class="px-4 mb-8 scroll-mt-36"
                >
                    <div class="flex justify-between items-end mb-4 px-1 border-b border-gray-100 pb-2">
                         <h3 class="text-xl font-bold text-slate-800 tracking-tight">{{ cat.name }}</h3>
                         <span class="text-xs font-bold text-gray-400 mb-1">{{ cat.products.length }} item</span>
                    </div>
                   
                    <div class="grid grid-cols-2 gap-4">
                        <!-- Standard Card -->
                         <div 
                            v-for="product in cat.products"
                            :key="product.id"
                            @click="router.push(`/app/product/${product.id}`)"
                            class="bg-white p-3 rounded-[20px] shadow-sm border border-gray-100 cursor-pointer active:scale-[0.98] transition-transform"
                        >
                            <div class="relative w-full aspect-square rounded-[16px] bg-[#F8F9FA] overflow-hidden mb-3">
                                <img :src="product.image_url || '/no-image.jpg'" class="w-full h-full object-cover mix-blend-multiply" />
                                <button @click.stop="toggleFavorite(product)" class="absolute top-2 right-2 w-7 h-7 rounded-full bg-white shadow-sm flex items-center justify-center transition-colors" :class="isFavorite(product) ? 'text-red-500' : 'text-gray-300 hover:text-red-500'">
                                    <HeartIcon class="w-4 h-4" :class="{ 'fill-current': isFavorite(product) }" />
                                </button>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-sm line-clamp-1 mb-1">{{ product.name }}</h4>
                                <p class="text-xs text-gray-400 line-clamp-2 mb-2 leading-relaxed">{{ product.description }}</p>
                                <div class="flex items-center justify-between mt-2">
                                     <div class="flex flex-col">
                                         <p v-if="product.original_price" class="text-[10px] text-gray-400 line-through">Rp {{ formatNumber(product.original_price) }}</p>
                                         <p class="font-bold text-slate-900">Rp {{ formatNumber(product.price) }}</p>
                                     </div>
                                     <div class="w-7 h-7 rounded-full bg-[#5a6c37] flex items-center justify-center text-white active:bg-slate-700 transition-colors">
                                         <PlusIcon class="w-4 h-4" />
                                     </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                
                <!-- Bottom Spacer -->
                <div class="h-20"></div>
            </div>
            
             <!-- Sticky Cart Bar -->
            <transition
                enter-active-class="transform transition duration-500 ease-out"
                enter-from-class="translate-y-full opacity-0"
                enter-to-class="translate-y-0 opacity-100"
                leave-active-class="transform transition duration-300 ease-in"
                leave-from-class="translate-y-0 opacity-100"
                leave-to-class="translate-y-full opacity-0"
            >
                <div v-if="cartCount > 0" class="fixed bottom-4 left-0 right-0 z-50 px-4 pointer-events-none">
                    <div class="pointer-events-auto w-full max-w-md mx-auto">
                        <!-- Guest Checkout Tooltip -->
                        <div v-if="!authStore?.isAuthenticated" class="mb-2 flex justify-center animate-bounce">
                            <div class="bg-gray-800 text-white text-xs py-1 px-3 rounded-full shadow-lg opacity-90">
                                Checking out as Guest
                            </div>
                        </div>
                        
                        <!-- Floating Cart Button -->
                        <router-link to="/app/checkout" class="flex items-center justify-between bg-[#5a6c37] text-white p-4 rounded-full shadow-2xl shadow-primary/30 cursor-pointer hover:bg-[#4a5c2e] transition-all active:scale-[0.98] ring-1 ring-white/10 backdrop-blur-sm">
                            <div class="flex items-center gap-3">
                                <div class="bg-white/20 p-2 rounded-full">
                                    <ShoppingBagIcon class="w-5 h-5 text-white" />
                                </div>
                                <div class="flex flex-col">
                                    <span class="text-xs font-medium opacity-90">Total Order</span>
                                    <span class="font-bold text-lg">{{ formatPrice(cartTotal) }}</span>
                                </div>
                            </div>
                            
                            <div class="flex items-center gap-2 bg-white text-[#5a6c37] px-4 py-1.5 rounded-full font-bold text-sm">
                                <span>{{ cartCount }} Items</span>
                                <ArrowRightIcon class="w-4 h-4" />
                            </div>
                        </router-link>
                    </div>
                </div>
            </transition>
        </div>
    </div>
</template>

<script setup>
import { onMounted, onUnmounted, computed, ref, nextTick, watch } from 'vue';
import { ChevronLeftIcon, SearchIcon, PlusIcon, ShoppingBagIcon, ChevronRightIcon, ThumbsUpIcon, HeartIcon, ArrowRightIcon, MapPinIcon } from 'lucide-vue-next';
import { useCustomerStore } from '../../stores/customer';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { useRouter, useRoute } from 'vue-router';
import { useToast } from "vue-toastification";

const router = useRouter();
const route = useRoute();
const store = useCustomerStore();
const authStore = useMemberAuthStore();
const toast = useToast();

const favorites = computed(() => store.favorites);
const showFavorites = ref(store.favorites.length > 0);

const isFavorite = (item) => favorites.value.some(f => f.id === item.id);

const toggleFavorite = (item) => {
    const isAdded = store.toggleFavorite(item);
    
    if (isAdded) {
        showFavorites.value = true;
        activeSection.value = 'favorites';
    } else {
        if (favorites.value.length === 0) {
            showFavorites.value = false;
            activeSection.value = 'recommended';
        }
    }
};

const activeSection = ref('recommended');
const loadingRecommended = ref(false);

const recommendedItems = computed(() => store.recommendedProducts);

const groupedProducts = computed(() => {
    return store.categories.map(cat => ({
        ...cat,
        products: store.products.filter(p => p.category_id === cat.id)
    })).filter(g => g.products.length > 0);
});

const nonEmptyCategories = computed(() => {
    return store.categories.filter(cat => 
        store.products.some(p => p.category_id === cat.id)
    );
});

const cartTotal = computed(() => store.cartTotal);
const cartCount = computed(() => store.cartCount);

// Helper
const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);
const formatPrice = (value) => 
    new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(value);


const isManualScroll = ref(false);

const scrollToSection = (slug) => {
    isManualScroll.value = true;
    activeSection.value = slug;
    
    // Smooth scroll
    const el = document.getElementById('sec-' + slug);
    
    if (el) {
        // Adjust for sticky header offset if necessary, typically scrollIntoView block: 'start' aligns with container top
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
    
    setTimeout(() => {
        isManualScroll.value = false;
    }, 1000);
};

const handleScroll = () => {
    if (isManualScroll.value) return;
    
    const container = document.getElementById('menu-container');
    if (!container) return;
    
    const containerRect = container.getBoundingClientRect();
    // Use a trigger line slightly below the top of the container to catch the active section
    // The tabs might occupy ~50px above.
    const triggerTop = containerRect.top + 80; 
    
    // Check Recommended or Favorites
    const recEl = document.getElementById('sec-recommended');
    const favEl = document.getElementById('sec-favorites');
    
    if (recEl) {
        const rect = recEl.getBoundingClientRect();
        if (rect.top <= triggerTop && rect.bottom > triggerTop) {
            if (activeSection.value !== 'recommended') activeSection.value = 'recommended';
            return;
        }
    } else if (favEl) {
         const rect = favEl.getBoundingClientRect();
        if (rect.top <= triggerTop && rect.bottom > triggerTop) {
            if (activeSection.value !== 'favorites') activeSection.value = 'favorites';
            return;
        }
    }
    
    // Check Categories
    for (const cat of groupedProducts.value) {
        const el = document.getElementById('sec-' + cat.slug);
        if (el) {
            const rect = el.getBoundingClientRect();
            // If top of section is above trigger, and bottom is below trigger, it's the active one
            if (rect.top <= triggerTop && rect.bottom > triggerTop) {
                 if (activeSection.value !== cat.slug) activeSection.value = cat.slug;
                 return;
            }
        }
    }
};

onMounted(async () => {
    await store.fetchCategories();
    await store.fetchProducts({ per_page: 100 }); 
    
    loadingRecommended.value = true;
    await store.fetchRecommendedProducts();
    loadingRecommended.value = false;
    
    nextTick(() => {
        const container = document.getElementById('menu-container');
        if (container) {
            container.addEventListener('scroll', handleScroll, { passive: true });
        }
    });
});

onUnmounted(() => {
    const container = document.getElementById('menu-container');
    if (container) {
        container.removeEventListener('scroll', handleScroll);
    }
});
</script>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
