<template>
    <MobileLayout :showHeader="false" :showFooter="true">
        <div class="bg-white font-sans text-slate-900 pb-32">
            
            <!-- Custom Green Header -->
            <header class="bg-primary px-5 pt-6 pb-6 rounded-b-[32px] shadow-lg shadow-primary/20 relative z-10">
                <div class="flex items-start justify-between mb-6">
                    <div class="flex flex-col items-start gap-1">
                        <img v-if="settings?.store_logo" :src="settings.store_logo" class="h-14 w-auto object-contain" :alt="settings?.store_name">
                        <span v-else class="text-xl font-bold text-white">RB</span>
                        <p class="text-xs text-white/90 italic font-medium tracking-wide">Alam Menyapa, Kopi Bercerita</p>
                    </div>
                    
                    <div class="flex items-center gap-2">
                        <button v-if="member" @click="$router.push('/rewards')" class="h-10 px-3 rounded-full bg-white/10 backdrop-blur-md flex items-center justify-center text-white border border-white/10 active:bg-white/20 transition-colors gap-2">
                            <CoinsIcon class="w-4 h-4 text-yellow-400 fill-current" />
                            <span class="text-xs font-bold">{{ member.points_balance || 0 }}</span>
                        </button>
                        
                        <button @click="$router.push('/profile')" class="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md flex items-center justify-center text-white border border-white/10 active:bg-white/20 transition-colors">
                            <UserIcon class="w-5 h-5" v-if="!member" />
                            <img v-else :src="member.avatar_url || `https://ui-avatars.com/api/?name=${member.name}&background=ffffff&color=006041`" class="w-full h-full rounded-full object-cover" />
                        </button>
                        <button @click="$router.push('/cart')" class="w-10 h-10 rounded-full bg-white/10 backdrop-blur-md flex items-center justify-center text-white border border-white/10 active:bg-white/20 transition-colors relative">
                            <ShoppingBagIcon class="w-5 h-5" />
                            <span v-if="store.cartCount > 0" class="absolute top-2.5 right-2.5 w-2 h-2 bg-red-400 rounded-full border border-primary"></span>
                        </button>
                    </div>
                </div>
                <!-- Search Bar Row -->
                <div class="flex gap-3">
                    <div class="flex-1 h-12 bg-white rounded-2xl flex items-center px-4 gap-3 shadow-sm">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                        <input 
                            type="text" 
                            v-model="searchQuery"
                            placeholder="Search coffee..." 
                            class="flex-1 bg-transparent border-none outline-none text-sm font-medium text-slate-800 placeholder:text-gray-400"
                            @keydown.enter="handleSearch"
                        />
                    </div>
                    <button class="w-12 h-12 bg-white rounded-2xl flex items-center justify-center text-primary shadow-sm active:scale-95 transition-transform">
                        <CoffeeIcon class="w-6 h-6" />
                    </button>
                </div>
            </header>

            <main class="w-full px-5 mt-6">
                <!-- Banner Slider -->
                <div class="w-full h-[160px] rounded-[24px] relative overflow-hidden shadow-lg shadow-primary/10">
                    <div 
                        v-for="(banner, index) in activeBanners" 
                        :key="banner.id || 'static'"
                        class="absolute inset-0 transition-opacity duration-700 ease-in-out"
                        :class="{ 'opacity-100 z-10': currentBannerIndex === index, 'opacity-0 z-0': currentBannerIndex !== index }"
                    >
                        <!-- Background Image -->
                         <div class="absolute inset-0 bg-[#5a6c37]">
                             <img v-if="banner.image_url" :src="banner.image_url" class="number-hide w-full h-full object-cover">
                        </div>
                         <!-- Overlay Gradient -->
                         <div class="absolute inset-0 bg-linear-to-r from-black/60 to-transparent"></div>
                        
                        <div class="relative z-20 h-full flex items-center p-6">
                            <div class="flex-1 text-white">
                                <div v-if="banner.title" class="inline-block px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-[10px] font-bold uppercase tracking-wider mb-2">
                                     Limited Offer
                                </div>
                                <h2 class="text-2xl font-bold leading-tight mb-1 line-clamp-2 max-w-[80%]">{{ banner.title || 'Special Offer' }}</h2>
                                <p class="text-sm opacity-90 line-clamp-1 mb-0">{{ banner.description || 'Get amazing deals today!' }}</p>
                            </div>
                            <div class="w-[80px] h-full relative flex items-end justify-end pb-2">
                                 <button 
                                    v-if="banner.action_link"
                                    @click="handleBannerClick(banner)"
                                    class="bg-[#EDB01D] text-[#5a6c37] text-xs font-bold px-4 py-2 rounded-xl shadow-lg active:scale-95 transition-transform"
                                 >
                                    {{ banner.action_label || 'Claim' }}
                                 </button>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Pagination Dots -->
                    <div class="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5 z-30" v-if="activeBanners.length > 1">
                        <div 
                            v-for="(banner, index) in activeBanners" 
                            :key="index"
                            class="h-1.5 rounded-full transition-all duration-300"
                            :class="currentBannerIndex === index ? 'w-4 bg-white' : 'w-1.5 bg-white/30'"
                            @click="currentBannerIndex = index"
                        ></div>
                    </div>
                </div>

                <!-- Action Cards (Pickup / Dine In) -->
                <div class="mt-6 grid grid-cols-2 gap-4">
                    <!-- Picker Order -->
                    <button 
                        @click="setOrderType('pickup')"
                        class="bg-white p-4 rounded-[20px] border border-gray-100 shadow-sm flex flex-col items-start gap-3 active:scale-[0.98] transition-all group hover:border-primary/30"
                        :class="orderType === 'pickup' ? 'ring-2 ring-primary bg-primary/5' : ''"
                    >
                        <div class="w-12 h-12 rounded-full bg-[#f5f5f5] flex items-center justify-center group-hover:bg-primary/10 transition-colors">
                            <ShoppingBagIcon class="w-6 h-6 text-slate-700 group-hover:text-primary" />
                        </div>
                        <div class="text-left">
                            <h3 class="text-base font-bold text-slate-900 group-hover:text-primary">Pick Up</h3>
                            <p class="text-xs text-slate-400 font-medium leading-relaxed mt-1">Take it at the store, no queue</p>
                        </div>
                    </button>

                    <!-- Dine In -->
                    <button 
                        @click="setOrderType('dine_in')"
                        class="bg-white p-4 rounded-[20px] border border-gray-100 shadow-sm flex flex-col items-start gap-3 active:scale-[0.98] transition-all group hover:border-primary/30"
                        :class="orderType === 'dine_in' ? 'ring-2 ring-primary bg-primary/5' : ''"
                    >
                        <div class="w-12 h-12 rounded-full bg-[#f5f5f5] flex items-center justify-center group-hover:bg-primary/10 transition-colors">
                            <UtensilsIcon class="w-6 h-6 text-slate-700 group-hover:text-primary" />
                        </div>
                        <div class="text-left">
                            <h3 class="text-base font-bold text-slate-900 group-hover:text-primary">Dine In</h3>
                            <p class="text-xs text-slate-400 font-medium leading-relaxed mt-1">Eat comfortably at our place</p>
                        </div>
                    </button>
                </div>

                <!-- Recommended Section -->
                <div class="mt-8">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-bold text-slate-900">Bincang Rasa</h3>
                        <button @click="$router.push({ path: '/order', query: { filter: 'recommended' } })" class="text-sm font-bold text-primary hover:underline">See All</button>
                    </div>

                    <!-- Category Pills -->
                    <div class="flex gap-2 overflow-x-auto no-scrollbar pb-4">
                         <button 
                            v-for="cat in quickCategories" 
                            :key="cat"
                            class="px-5 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors border flex items-center justify-center"
                            :class="selectedCategory === cat ? 'bg-primary text-white border-primary' : 'bg-white text-slate-600 border-gray-200 hover:bg-gray-50'"
                            @click="handleCategorySelect(cat)"
                         >
                            <ThumbsUpIcon v-if="cat === 'All'" class="w-4 h-4" />
                            <span v-else>{{ cat }}</span>
                         </button>
                    </div>

                    <!-- Product Grid -->
                    <div v-if="loading" class="grid grid-cols-2 gap-4">
                        <div v-for="i in 4" :key="i" class="h-[220px] rounded-[20px] bg-gray-100 animate-pulse"></div>
                    </div>

                    <div v-else class="grid grid-cols-2 gap-4">
                        <div 
                            v-for="item in displayedProducts" 
                            :key="item.id"
                            @click="$router.push(`/product/${item.slug}`)" 
                            class="bg-white p-3 rounded-[20px] shadow-sm border border-gray-100 cursor-pointer active:scale-[0.98] transition-transform"
                        >
                            <div class="relative w-full aspect-square rounded-[16px] bg-[#F8F9FA] overflow-hidden mb-3">
                                <img :src="item.image_url || '/no-image.jpg'" class="w-full h-full object-cover mix-blend-multiply" />
                                <button @click.stop="toggleFavorite(item)" class="absolute top-2 right-2 w-7 h-7 rounded-full bg-white shadow-sm flex items-center justify-center transition-colors" :class="isFavorite(item) ? 'text-red-500' : 'text-gray-300 hover:text-red-500'">
                                    <HeartIcon class="w-4 h-4" :class="{ 'fill-current': isFavorite(item) }" />
                                </button>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-sm line-clamp-1">{{ item.name }}</h4>
                                <p class="text-xs text-gray-500 line-clamp-2 mt-1 leading-snug">{{ item.description }}</p>
                                <div class="flex items-center justify-between mt-2">
                                     <p class="font-bold text-slate-900">Rp {{ formatNumber(store.resolveProductPrice(item)) }}</p>
                                     <div class="w-7 h-7 rounded-full bg-[#5a6c37] flex items-center justify-center text-white">
                                         <PlusIcon class="w-4 h-4" />
                                     </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </main>
        </div>
    </MobileLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { useCustomerStore } from '../../stores/customer';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { useRouter } from 'vue-router';
import { 
    BellIcon, StoreIcon, UtensilsIcon, MapPinIcon, 
    ChevronDownIcon, UserIcon, CoinsIcon, CoffeeIcon, ShoppingBagIcon,
    HeartIcon, PlusIcon, SearchIcon, SlidersHorizontalIcon, ScanLineIcon, ThumbsUpIcon
} from 'lucide-vue-next';

const router = useRouter();
const store = useCustomerStore();
const authStore = useMemberAuthStore();

const member = computed(() => authStore.currentUser);
const settings = computed(() => store.settings);
const featuredProducts = computed(() => store.products.slice(0, 6));
const loading = computed(() => store.loading);

const orderType = ref(localStorage.getItem('orderType') || 'pickup');
const selectedCategory = ref('All');

const quickCategories = computed(() => {
    const cats = store.categories.map(c => c.name);
    return ['All', ...cats];
});

const displayedProducts = computed(() => {
    if (selectedCategory.value === 'All') {
        return store.recommendedProducts;
    }
    return store.products;
});

const handleCategorySelect = (catName) => {
    selectedCategory.value = catName;
    if (catName === 'All') {
        // Already loaded recommended
    } else {
        const cat = store.categories.find(c => c.name === catName);
        if (cat) {
            store.fetchProducts({ category_id: cat.id, per_page: 6 });
        }
    }
};

const searchQuery = ref('');

const handleSearch = () => {
    if (searchQuery.value.trim()) {
        router.push({ path: '/order', query: { q: searchQuery.value } });
    }
};

const getTimeGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
};

const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);

const setOrderType = (type) => {
    orderType.value = type;
    store.setOrderType(type);
    router.push('/order');
};

onMounted(() => {
    store.fetchCategories();
    store.fetchRecommendedProducts(); 
    store.fetchSettings();
    store.fetchBanners(); 
    if (authStore.isAuthenticated && !authStore.user) {
        authStore.fetchMe();
    }
    startBannerTimer();
});

const activeBanners = computed(() => {
    // If we have banners, use them
    if (store.banners && store.banners.length > 0) return store.banners.filter(b => b.is_active);
    
    // Default Fallback Banner if none
    return [{
        id: 'default',
        title: 'Jadi Bagian Bincang di Ruang Kita',
        description: 'Get Free Up to 20% Discount!',
        image_url: null, 
        action_label: 'Claim',
        action_link: '/promo'
    }];
});

const currentBannerIndex = ref(0);
let bannerInterval = null;

const startBannerTimer = () => {
    if (activeBanners.value.length <= 1) return;
    bannerInterval = setInterval(() => {
        currentBannerIndex.value = (currentBannerIndex.value + 1) % activeBanners.value.length;
    }, 5000);
};

const handleBannerClick = (banner) => {
    if (banner.action_link) {
        router.push(banner.action_link);
    }
};

const isFavorite = (item) => store.favorites.some(f => f.id === item.id);
const toggleFavorite = (item) => store.toggleFavorite(item);
</script>

