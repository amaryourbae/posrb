<template>
    <div class="min-h-screen flex justify-center bg-gray-100 font-sans">
        <div class="w-full max-w-md bg-white min-h-screen shadow-2xl relative flex flex-col">
            <!-- Header -->
            <div class="sticky top-0 z-20 bg-white/95 backdrop-blur-md shadow-sm">
                <div class="flex items-center px-4 py-3 justify-between border-b border-gray-50">
                     <button @click="$router.back()" class="text-gray-900 flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors">
                        <ChevronLeftIcon class="w-6 h-6" />
                    </button>
                     <h2 class="text-slate-800 text-lg font-bold leading-tight tracking-tight">RBC Talk+</h2>
                     <button @click="$router.push('/app/vouchers')" class="flex w-10 h-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-100 transition-colors text-gray-900 relative">
                        <TicketIcon class="w-6 h-6" />
                    </button>
                </div>
            </div>

            <div class="flex-1 overflow-y-auto pb-32 no-scrollbar scroll-smooth bg-gray-50/50">
                <div class="p-4 space-y-6">
                    <div class="mb-2">
                        <h1 class="text-xl font-black text-slate-800 leading-tight">Talk & Loyalty Poin</h1>
                        <p class="text-sm text-gray-500 font-medium mt-1">Ngopi, Ngobrol + dapet Benefit.</p>
                    </div>

                    <!-- Points Card (Styled like Location Card in Menu) -->
                    <div class="bg-linear-to-r from-[#5a6c37] to-[#7a8c50] rounded-xl p-5 flex items-center justify-between text-white relative overflow-hidden shadow-lg shadow-green-900/20">
                        <!-- Decorative circles -->
                        <div class="absolute -right-4 -top-4 w-20 h-20 bg-white/10 rounded-full"></div>
                        <div class="absolute right-10 -bottom-10 w-24 h-24 bg-white/5 rounded-full"></div>

                        <div class="z-10 flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                                    <CoinsIcon class="w-4 h-4 text-white" />
                                </div>
                                <span class="font-bold text-2xl">{{ member?.points_balance || 0 }} Poin</span>
                            </div>
                            <p class="text-xs text-white/90 font-medium pl-1">Dapatkan Poin dari setiap transaksi</p>
                        </div>
                    </div>

                    <!-- Rewards Grid -->
                    <div>
                        <div class="flex justify-between items-end mb-4 px-1 border-b border-gray-100 pb-2">
                             <h3 class="text-xl font-bold text-slate-800 tracking-tight">Tukar Poin</h3>
                             <span class="text-xs font-bold text-gray-400 mb-1">{{ rewards.length }} rewards</span>
                        </div>

                        <div class="grid grid-cols-2 gap-4">
                            <div 
                                v-for="reward in rewards" 
                                :key="reward.id" 
                                @click="viewReward(reward)"
                                class="bg-white p-3 rounded-[20px] shadow-sm border border-gray-100 cursor-pointer active:scale-[0.98] transition-transform flex flex-col h-full"
                            >
                                <div class="relative w-full aspect-square rounded-[16px] bg-[#F8F9FA] overflow-hidden mb-3">
                                    <img :src="reward.image_url || '/no-image.jpg'" class="w-full h-full object-cover mix-blend-multiply" />
                                    
                                    <!-- Missing Points Badge -->
                                    <div v-if="pointsMissing(reward) > 0" class="absolute inset-0 bg-white/60 backdrop-blur-[1px] flex items-center justify-center">
                                        <div class="bg-red-500 text-white text-[10px] font-bold px-2 py-1 rounded-full shadow-sm">
                                            Kurang {{ pointsMissing(reward) }} Poin
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="flex-1 flex flex-col">
                                    <h4 class="font-bold text-slate-900 text-sm line-clamp-2 mb-1 leading-snug">{{ reward.name }}</h4>
                                    
                                    <div class="mt-auto flex items-center justify-between pt-2">
                                        <div class="flex items-center gap-1">
                                            <CoinsIcon class="w-3.5 h-3.5 text-yellow-500" />
                                            <span class="font-bold text-slate-900 text-sm">{{ reward.point_cost }}</span>
                                        </div>
                                        <div class="w-7 h-7 rounded-full flex items-center justify-center text-white transition-colors"
                                            :class="pointsMissing(reward) > 0 ? 'bg-gray-200' : 'bg-[#5a6c37] active:bg-slate-700'">
                                            <ArrowRightIcon class="w-4 h-4" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, computed } from 'vue';
import { useCustomerStore } from '../../../stores/customer';
import { useMemberAuthStore } from '../../../stores/memberAuth';
import { useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { ChevronLeftIcon, TicketIcon, CoinsIcon, ArrowRightIcon } from 'lucide-vue-next';

const router = useRouter();
const store = useCustomerStore();
const authStore = useMemberAuthStore();
const { rewards } = storeToRefs(store);

const member = computed(() => authStore.currentUser);

onMounted(() => {
    store.fetchRewards();
    if (authStore.isAuthenticated) {
        authStore.fetchMe(); // Ensure fresh points
    }
});

const pointsMissing = (reward) => {
    const current = member.value?.points_balance || 0;
    return Math.max(0, reward.point_cost - current);
};

const viewReward = (reward) => {
    router.push(`/app/rewards/${reward.id}`);
};
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
