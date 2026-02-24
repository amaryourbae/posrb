<template>
<MobileLayout :showHeader="false" :showFooter="true">
    <div class="flex flex-col min-h-screen bg-white font-display text-slate-900 pb-1">
        <!-- Header -->
        <header class="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100 flex items-center justify-between px-5 py-4">
            <div class="flex items-center gap-3">
                <button @click="$router.go(-1)" class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 -ml-2">
                    <ChevronLeftIcon class="w-5 h-5 text-slate-700" />
                </button>
                <h1 class="text-xl font-bold tracking-tight text-slate-900">Profil Saya</h1>
            </div>
            <button @click="logout" class="p-2 text-slate-400 hover:text-red-500 transition-colors rounded-full hover:bg-red-50">
                <LogOutIcon class="w-5 h-5" />
            </button>
        </header>

        <main class="flex-1 w-full px-5 pb-5 pt-6 space-y-6 overflow-y-auto no-scrollbar">
            <!-- Skeleton Loader -->
            <div v-if="loading" class="animate-pulse space-y-6">
                <!-- Profile Header Skeleton -->
                <div class="flex items-center gap-4">
                    <div class="w-16 h-16 bg-gray-200 rounded-full"></div>
                    <div class="flex-1 space-y-2">
                        <div class="h-5 w-40 bg-gray-200 rounded"></div>
                        <div class="h-4 w-24 bg-gray-200 rounded"></div>
                    </div>
                </div>

                <!-- Card Skeleton -->
                <div class="w-full h-48 rounded-2xl bg-gray-200"></div>

                <!-- Grid Skeleton -->
                <div class="grid grid-cols-3 gap-2">
                    <div v-for="i in 3" :key="i" class="h-24 bg-gray-200 rounded-2xl"></div>
                </div>
            </div>

            <!-- Real Content -->
            <template v-else>
                <!-- User Profile Header -->
                <div class="flex items-center gap-4">
                    <div class="relative">
                        <img 
                            :src="member?.avatar_url || 'https://ui-avatars.com/api/?name=' + (member?.name || 'User') + '&background=random'" 
                            class="w-16 h-16 rounded-full object-cover border-2 border-white shadow-sm"
                            alt="Profile"
                        />
                        <div class="absolute -bottom-1 -right-1 bg-white p-1 rounded-full">
                            <div class="bg-yellow-400 p-1 rounded-full">
                                <StarIcon class="w-3 h-3 text-white fill-current" />
                            </div>
                        </div>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h2 class="text-lg font-bold text-slate-900 truncate">{{ member?.name || 'Tamu' }}</h2>
                        <p class="text-slate-500 text-sm truncate">{{ member?.phone || '-' }}</p>
                    </div>
                    <button @click="$router.push('/app/profile/edit')" class="text-sm font-semibold text-primary bg-primary/10 px-3 py-1.5 rounded-full">
                        Edit
                    </button>
                </div>
    
                <!-- Membership Card -->
                <div @click="$router.push('/app/rewards')" class="cursor-pointer w-full h-48 rounded-2xl bg-linear-to-br from-[#5a6c37] to-[#4a5930] shadow-lg shadow-primary/20 relative overflow-hidden flex flex-col justify-between p-6 text-white group active:scale-[0.98] transition-transform">
                    <!-- Background Pattern -->
                    <div class="absolute top-0 right-0 h-full w-1/2 flex items-center justify-center opacity-10 pointer-events-none group-hover:scale-105 transition-transform duration-700">
                        <img src="/bg-member.png" class="w-24 h-24 object-contain -mr-4 -mt-12" alt="Pattern" />
                    </div>
                    
                    <div class="relative z-10 flex justify-between items-start" v-if="tierInfo">
                        <div>
                            <p class="text-white/80 text-xs font-medium uppercase tracking-wider mb-1">Ruang Poin</p>
                            <h3 class="text-3xl font-extrabold tracking-tight">{{ formatNumber(member?.points_balance || 0) }}</h3>
                        </div>
                        <div class="bg-white/20 backdrop-blur-sm px-2.5 py-1 rounded-lg border border-white/10">
                            <span class="text-xs font-bold">{{ tierInfo?.current || 'Classic' }}</span>
                        </div>
                    </div>
    
                    <div class="relative z-10" v-if="tierInfo">
                        <div class="flex items-center gap-2 mb-2">
                            <div class="h-1.5 flex-1 bg-black/20 rounded-full overflow-hidden backdrop-blur-sm">
                                <div class="h-full bg-yellow-400 rounded-full shadow-[0_0_10px_rgba(250,204,21,0.5)] transition-all duration-1000" :style="{ width: (tierInfo?.progress || 0) + '%' }"></div>
                            </div>
                            <span class="text-[10px] font-medium text-white/90">{{ Math.round(tierInfo?.progress || 0) }}%</span>
                        </div>
                        <p class="text-[10px] text-white/70" v-if="tierInfo?.current !== 'Gold'">Kumpulkan {{ tierInfo?.remaining || 0 }} poin lagi untuk naik level {{ tierInfo?.next || 'Silver' }}</p>
                        <p class="text-[10px] text-white/70" v-else>Anda telah mencapai level tertinggi! Nikmati benefit eksklusif.</p>
                    </div>
                </div>
    
                <!-- Quick Actions Grid -->
                <div class="grid grid-cols-3 gap-2"> <!-- Changed to 3 cols -->
                    <button @click="$router.push('/app/orders')" class="flex flex-col items-center gap-2 p-3 rounded-2xl bg-white active:bg-gray-50 transition-colors shadow-sm border border-gray-100">
                        <div class="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
                            <ShoppingBagIcon class="w-5 h-5" />
                        </div>
                        <span class="text-[10px] font-semibold text-slate-600 text-center">Pesanan</span>
                    </button>
                    <button @click="$router.push('/app/promo')" class="flex flex-col items-center gap-2 p-3 rounded-2xl bg-white active:bg-gray-50 transition-colors shadow-sm border border-gray-100">
                        <div class="w-10 h-10 rounded-full bg-orange-50 flex items-center justify-center text-orange-600">
                            <TicketIcon class="w-5 h-5" />
                        </div>
                        <span class="text-[10px] font-semibold text-slate-600 text-center">Voucher</span>
                    </button>
                    <!-- Help Center -->
                    <button @click="$router.push('/app/help')" class="flex flex-col items-center gap-2 p-3 rounded-2xl bg-white active:bg-gray-50 transition-colors shadow-sm border border-gray-100">
                        <div class="w-10 h-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
                            <HeadphonesIcon class="w-5 h-5" />
                        </div>
                        <span class="text-[10px] font-semibold text-slate-600 text-center">Bantuan</span>
                    </button>
                </div>
            </template>

            <!-- Menu List -->
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <div class="p-4 border-b border-gray-50">
                    <h3 class="text-sm font-bold text-slate-900">Akun Saya</h3>
                </div>
                <div>
                    <button @click="$router.push('/app/profile/edit')" class="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors text-left border-b border-gray-50 last:border-0">
                        <div class="flex items-center gap-3">
                            <UserIcon class="w-5 h-5 text-gray-400" />
                            <span class="text-sm font-medium text-slate-700">Edit Profil</span>
                        </div>
                        <ChevronRightIcon class="w-4 h-4 text-gray-300" />
                    </button>

                    <button @click="$router.push('/app/profile/security')" class="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors text-left">
                        <div class="flex items-center gap-3">
                            <LockIcon class="w-5 h-5 text-gray-400" />
                            <span class="text-sm font-medium text-slate-700">Keamanan</span>
                        </div>
                        <ChevronRightIcon class="w-4 h-4 text-gray-300" />
                    </button>
                </div>
            </div>

            <!-- Info Menu List -->
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-6">
                <div class="p-4 border-b border-gray-50">
                    <h3 class="text-sm font-bold text-slate-900">Info Lainnya</h3>
                </div>
                <div>
                    <button @click="$router.push('/app/profile/terms')" class="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors text-left border-b border-gray-50 last:border-0">
                        <div class="flex items-center gap-3">
                            <FileTextIcon class="w-5 h-5 text-gray-400" />
                            <span class="text-sm font-medium text-slate-700">Syarat & Ketentuan</span>
                        </div>
                        <ChevronRightIcon class="w-4 h-4 text-gray-300" />
                    </button>
                    <button @click="$router.push('/app/profile/privacy')" class="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors text-left">
                        <div class="flex items-center gap-3">
                            <ShieldIcon class="w-5 h-5 text-gray-400" />
                            <span class="text-sm font-medium text-slate-700">Kebijakan Privasi</span>
                        </div>
                        <ChevronRightIcon class="w-4 h-4 text-gray-300" />
                    </button>
                </div>
            </div>

            <!-- Social Media -->
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-4 mb-4">
                <h3 class="text-sm font-bold text-slate-900 mb-4">Media Sosial</h3>
                <div class="flex flex-col gap-3">
                    <a href="https://instagram.com/ruangbincang.coffee" target="_blank" class="flex items-center gap-3 px-4 py-3 bg-pink-50 text-pink-600 rounded-xl hover:bg-pink-100 transition-colors">
                        <InstagramIcon class="w-5 h-5" />
                        <span class="text-xs font-bold">@ruangbincang.coffee</span>
                    </a>
                    <a href="https://tiktok.com/@ruangbincang.coffee" target="_blank" class="flex items-center gap-3 px-4 py-3 bg-black/5 text-black rounded-xl hover:bg-black/10 transition-colors">
                       <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1-.1z"/></svg>
                        <span class="text-xs font-bold">@ruangbincang.coffee</span>
                    </a>
                </div>
            </div>

            <p class="text-center text-[10px] text-gray-300 py-4">
                Versi Aplikasi 1.0.2 (Build 2026)
            </p>
            <!-- Logout Modal -->
            <transition
                enter-active-class="transition duration-200 ease-out"
                enter-from-class="opacity-0 scale-95"
                enter-to-class="opacity-100 scale-100"
                leave-active-class="transition duration-150 ease-in"
                leave-from-class="opacity-100 scale-100"
                leave-to-class="opacity-0 scale-95"
            >
                <div v-if="showLogoutModal" class="fixed inset-0 z-60 flex items-center justify-center p-4">
                    <!-- Backdrop -->
                    <div class="absolute inset-0 bg-black/50 backdrop-blur-sm" @click="showLogoutModal = false"></div>
                    
                    <!-- Modal Content -->
                    <div class="relative w-full max-w-[320px] bg-white rounded-2xl p-6 shadow-xl transform transition-all">
                        <div class="text-center">
                            <div class="w-12 h-12 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-4">
                                <LogOutIcon class="w-6 h-6 text-red-500" />
                            </div>
                            <h3 class="text-lg font-bold text-slate-900 mb-2">Keluar Aplikasi?</h3>
                            <p class="text-sm text-slate-500 mb-6 leading-relaxed">
                                Apakah Anda yakin ingin keluar dari akun Anda? Anda perlu login kembali untuk mengakses pesanan.
                            </p>
                            
                            <div class="flex gap-3">
                                <button 
                                    @click="showLogoutModal = false"
                                    class="flex-1 py-2.5 rounded-xl border border-gray-200 text-slate-700 font-bold text-sm hover:bg-gray-50 active:scale-[0.98] transition-all"
                                >
                                    Batal
                                </button>
                                <button 
                                    @click="confirmLogout"
                                    class="flex-1 py-2.5 rounded-xl bg-red-600 text-white font-bold text-sm hover:bg-red-700 active:scale-[0.98] transition-all shadow-lg shadow-red-200"
                                >
                                    Ya, Keluar
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </transition>
        </main>
    </div>
</MobileLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import MobileLayout from '../../layouts/MobileLayout.vue';
import { useMemberAuthStore } from '../../stores/memberAuth';
import { 
    CoffeeIcon, StarIcon, TicketIcon, LogOutIcon, 
    ShoppingBagIcon, WalletIcon, HeadphonesIcon,
    UserIcon, MapPinIcon, LockIcon, ChevronRightIcon,
    ChevronLeftIcon, FileTextIcon, ShieldIcon, InstagramIcon
} from 'lucide-vue-next';

const router = useRouter();
const authStore = useMemberAuthStore();
const member = computed(() => authStore.currentUser);
const showLogoutModal = ref(false);

const formatNumber = (num) =>  new Intl.NumberFormat('id-ID').format(num);

const tierInfo = computed(() => {
    const p = Number(member.value?.points_balance) || 0;
    
    // Tier Logic: Classic (0-50), Silver (51-150), Gold (151+)
    if (p < 50) {
        return { 
            current: 'Classic', 
            next: 'Silver', 
            goal: 50, 
            remaining: 50 - p,
            progress: Math.min((p / 50) * 100, 100) 
        };
    } else if (p < 150) {
         return { 
            current: 'Silver', 
            next: 'Gold', 
            goal: 150, 
            remaining: 150 - p,
            progress: Math.min(((p - 50) / 100) * 100, 100) 
        };
    } else {
         return { 
            current: 'Gold', 
            next: 'Platinum', 
            goal: 150, 
            remaining: 0,
            progress: 100 
        };
    }
});

const loading = ref(true);

const logout = () => {
    showLogoutModal.value = true;
};

const confirmLogout = async () => {
    showLogoutModal.value = false;
    await authStore.logout();
    router.push('/app/login');
};

onMounted(async () => {
    try {
        await authStore.fetchMe();
    } finally {
        loading.value = false;
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
