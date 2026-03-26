<template>
    <div class="fixed inset-0 w-full bg-gray-50 font-sans text-gray-900 flex justify-center">
        <div class="w-full max-w-md bg-white h-full shadow-2xl relative flex flex-col">
            <!-- Top App Bar -->
            <header class="flex-none bg-white px-4 py-3 flex items-center justify-between border-b border-gray-100 shadow-sm z-20 sticky top-0">
                <router-link to="/order" class="size-10 flex items-center justify-center rounded-full hover:bg-gray-50 active:bg-gray-100 transition-colors text-gray-900">
                    <ChevronLeftIcon class="w-6 h-6" />
                </router-link>
                <h1 class="text-lg font-bold tracking-tight text-gray-900 absolute left-1/2 -translate-x-1/2">My Cart</h1>
                <div class="size-10"></div>
            </header>

            <!-- Scrollable Main Content -->
            <main class="flex-1 overflow-y-auto no-scrollbar">
                <div class="flex flex-col gap-6 p-4">
                    <!-- Loading State -->
                    <div v-if="loading" class="flex flex-col gap-6">
                        <div class="flex flex-col gap-4">
                            <div v-for="i in 3" :key="i" class="bg-white rounded-xl p-3 flex gap-4 shadow-sm border border-gray-100 animate-pulse">
                                <div class="shrink-0 size-20 rounded-lg bg-gray-200"></div>
                                <div class="flex flex-col flex-1 justify-between min-h-[80px]">
                                    <div class="space-y-2">
                                        <div class="h-4 bg-gray-200 rounded w-3/4"></div>
                                        <div class="h-3 bg-gray-200 rounded w-1/2"></div>
                                    </div>
                                    <div class="flex justify-between items-end mt-2">
                                        <div class="h-4 bg-gray-200 rounded w-16"></div>
                                        <div class="h-8 w-24 bg-gray-200 rounded-full"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <!-- Voucher Skeleton -->
                        <div class="w-full h-14 bg-gray-200 rounded-xl animate-pulse"></div>
                        <!-- Summary Skeleton -->
                        <div class="h-32 bg-gray-200 rounded-xl animate-pulse"></div>
                    </div>

                    <!-- Empty State -->
                    <div v-else-if="cart.length === 0" class="flex flex-col items-center justify-center py-20 text-center">
                        <ShoppingBagIcon class="w-16 h-16 text-gray-300 mb-4" />
                        <h3 class="text-lg font-bold text-gray-900">Your cart is empty</h3>
                        <p class="text-gray-500 text-sm mt-1">Looks like you haven't added anything yet.</p>
                        <router-link to="/order" class="mt-6 px-6 py-2 bg-primary text-white font-bold rounded-lg shadow-lg shadow-primary/20">
                            Start Ordering
                        </router-link>
                    </div>

                    <div v-else class="flex flex-col gap-6">
                        <!-- Items List -->
                        <div class="flex flex-col gap-4">
                            <div v-for="item in cart" :key="item.cartId" class="bg-white rounded-xl p-3 flex gap-4 shadow-sm border border-gray-100">
                                <div class="shrink-0 size-20 rounded-lg bg-gray-200 overflow-hidden">
                                    <img :src="item.image_url || '/no-image.jpg'" class="w-full h-full object-cover" />
                                </div>
                                <div class="flex flex-col flex-1 justify-between min-h-[80px]">
                                    <div>
                                        <h3 class="font-bold text-gray-900 leading-tight line-clamp-1">{{ getProductName(item) }}</h3>
                                        <p class="text-xs text-primary mt-1 leading-relaxed line-clamp-2">
                                            <template v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length">
                                                {{ getVisibleModifiers(item).map(m => m.option_name).join(', ') }}
                                            </template>
                                            <template v-else-if="!item.modifiers">
                                                {{ item.size }}, {{ item.ice }}, {{ item.sugar }}
                                            </template>
                                        </p>
                                    </div>
                                    <div class="flex items-end justify-between mt-2">
                                        <span class="font-bold text-primary">Rp {{ formatNumber(item.unit_price) }}</span>
                                        <!-- Quantity Control -->
                                        <div class="flex items-center gap-1 bg-gray-50 rounded-full p-1 h-8">
                                            <button @click="store.updateQuantity(item.cartId, -1)" class="size-6 flex items-center justify-center rounded-full bg-white shadow-sm text-gray-900 hover:text-primary disabled:opacity-50">
                                                <MinusIcon class="w-4 h-4" />
                                            </button>
                                            <span class="w-6 text-center text-sm font-bold text-gray-900">{{ item.quantity }}</span>
                                            <button @click="store.updateQuantity(item.cartId, 1)" class="size-6 flex items-center justify-center rounded-full bg-primary text-white shadow-sm hover:bg-primary/90">
                                                <PlusIcon class="w-4 h-4" />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Vouchers -->
                        <button 
                            @click="$router.push('/promo')"
                            class="w-full bg-white rounded-xl p-4 flex items-center gap-4 shadow-sm border border-gray-100 hover:bg-gray-50 transition-colors group"
                        >
                            <div class="flex items-center justify-center rounded-lg bg-primary/10 text-primary shrink-0 size-10 group-hover:scale-110 transition-transform">
                                <TicketIcon class="w-5 h-5" />
                            </div>
                            <div class="flex flex-col items-start flex-1" v-if="!store.selectedVoucher">
                                <p class="text-gray-900 text-base font-bold leading-normal">Vouchers &amp; Promo</p>
                                <p class="text-primary text-xs font-normal">Use a voucher to save more</p>
                            </div>
                            <div class="flex flex-col items-start flex-1" v-else>
                                <p class="text-base font-bold leading-normal text-green-700">Voucher Applied</p>
                                <p class="text-gray-500 text-xs font-normal line-clamp-1">{{ store.selectedVoucher.name }}</p>
                            </div>
                            
                            <div v-if="store.selectedVoucher" @click.stop="store.removeVoucher()" class="p-2 -mr-2 text-red-500 hover:bg-red-50 rounded-full cursor-pointer z-10">
                                <XIcon class="w-5 h-5" />
                            </div>
                            <ChevronRightIcon v-else class="w-5 h-5 text-gray-400" />
                        </button>

                        <!-- Price Breakdown Details -->
                        <div class="py-2 px-2 bg-gray-50/50 rounded-xl mt-2">
                            <div class="flex justify-between gap-x-6 py-2">
                                <p class="text-gray-500 text-sm font-medium leading-normal">Subtotal</p>
                                <p class="text-gray-900 text-sm font-bold leading-normal text-right">Rp {{ formatNumber(cartTotal) }}</p>
                            </div>
                            <div class="flex justify-between gap-x-6 py-2">
                                <p class="text-gray-500 text-sm font-medium leading-normal">Tax (10%)</p>
                                <p class="text-gray-900 text-sm font-bold leading-normal text-right">Rp {{ formatNumber(taxAmount) }}</p>
                            </div>
                            <div class="flex justify-between gap-x-6 py-2 border-t border-dashed border-gray-200 mt-2">
                                <p class="text-gray-900 text-base font-bold leading-normal">Total</p>
                                <p class="text-primary text-base font-bold leading-normal text-right">Rp {{ formatNumber(finalTotal) }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </main>

            <!-- Fixed Footer -->
            <footer v-if="cart.length > 0" class="flex-none w-full z-30 bg-white border-t border-gray-100 p-4 pb-safe shadow-[0_-4px_20px_-5px_rgba(0,0,0,0.1)]">
                <div class="flex gap-4 items-center">
                    <div class="flex flex-col flex-1">
                        <span class="text-xs text-gray-500 font-bold mb-0.5 uppercase tracking-wide">Total Payment</span>
                        <span class="text-xl font-bold text-primary">Rp {{ formatNumber(finalTotal) }}</span>
                    </div>
                    <router-link to="/checkout" class="bg-primary hover:bg-[#4a5c2e] text-white font-bold h-14 px-8 rounded-xl shadow-lg shadow-primary/20 flex items-center gap-2 transition-all active:scale-[0.98] flex-[1.5] justify-center">
                        <span>Checkout</span>
                        <ChevronRightIcon class="w-5 h-5" />
                    </router-link>
                </div>
            </footer>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { ChevronLeftIcon, MinusIcon, PlusIcon, TicketIcon, ChevronRightIcon, ShoppingBagIcon, CoffeeIcon, XIcon } from 'lucide-vue-next';
import { useCustomerStore } from '../../stores/customer';
import { useProductDisplay } from '../../composables/useProductDisplay';

const { getProductName, getVisibleModifiers } = useProductDisplay();

const store = useCustomerStore();
const cart = computed(() => store.cart);
const cartTotal = computed(() => store.cartTotal);
const taxAmount = computed(() => store.taxAmount);
const finalTotal = computed(() => store.finalTotal);

const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);

const loading = ref(true);

onMounted(() => {
    setTimeout(() => {
        loading.value = false;
    }, 500);
});
</script>

<style scoped>
.pb-safe {
    padding-bottom: max(env(safe-area-inset-bottom), 5px);
}
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
