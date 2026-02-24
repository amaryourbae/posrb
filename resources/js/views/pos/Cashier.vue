<template>
    <PosLayout @open-pending="isPendingBillsOpen = true">
        <!-- Print Receipt Component (Hidden on Screen) -->
        <Receipt :order="lastOrder || orderToPrint" />

        <div class="flex flex-col lg:flex-row h-full overflow-hidden relative">
            <!-- Main Content (Left Side - Product Grid) -->
            <div 
                class="flex-1 flex flex-col h-full relative overflow-hidden transition-all duration-300 ease-in-out"
                :class="{ 'lg:mr-[400px]': isCartOpen }"
            >
                
                <!-- Search Bar Area -->
                <div class="px-6 py-4 bg-white border-b border-gray-100 shrink-0">
                    <div class="relative max-w-md">
                        <SearchIcon class="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input 
                            v-model="search"
                            class="w-full pl-11 pr-4 py-2.5 bg-gray-100 border-none rounded-lg focus:ring-1 focus:ring-primary text-sm text-gray-800 placeholder-gray-500" 
                            placeholder="Search menu" 
                            type="text"
                        />
                    </div>
                </div>

                <!-- Categories -->
                <div class="px-6 py-4 overflow-x-auto no-scrollbar bg-white/50 shrink-0">
                    <div v-if="posStore.loading" class="flex space-x-3">
                        <div v-for="i in 6" :key="i" class="h-9 w-24 bg-gray-200 rounded-full animate-pulse shrink-0"></div>
                    </div>
                    <div v-else class="flex space-x-3">
                        <button 
                            @click="handleCategoryClick(null)"
                            class="px-5 py-2 rounded-full text-sm font-medium whitespace-nowrap transition border"
                            :class="selectedCategoryId === null 
                                ? 'bg-primary/10 border-primary text-primary font-bold' 
                                : 'bg-white border-gray-200 text-gray-600 hover:border-primary hover:text-primary'"
                        >
                            Popular
                        </button>
                        <button 
                            v-for="cat in categories" 
                            :key="cat.id"
                            @click="handleCategoryClick(cat)"
                            class="px-5 py-2 rounded-full text-sm font-medium whitespace-nowrap transition border"
                            :class="selectedCategoryId === cat.id 
                                ? 'bg-primary/10 border-primary text-primary font-bold' 
                                : 'bg-white border-gray-200 text-gray-600 hover:border-primary hover:text-primary'"
                        >
                            {{ cat.name }}
                        </button>
                    </div>
                </div>

                <!-- Product Grid -->
                <div class="flex-1 overflow-y-auto px-6 pb-6 scroll-smooth bg-gray-50">
                    <div v-if="posStore.loading" class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 pt-2">
                        <div v-for="i in 8" :key="i" class="bg-white rounded-xl p-3 shadow-sm border border-transparent h-full animate-pulse flex flex-col">
                            <div class="w-full aspect-square rounded-lg bg-gray-200 mb-3"></div>
                            <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                            <div class="h-4 bg-gray-200 rounded w-1/4 mt-auto"></div>
                        </div>
                    </div>
                    <div v-else-if="products.length === 0" class="flex flex-col items-center justify-center h-64 text-gray-400">
                        <p>No products found</p>
                    </div>
                    <div v-else class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 pt-2">
                        <div 
                            v-for="product in products" 
                            :key="product.id"
                            class="bg-white rounded-xl p-3 shadow-sm hover:shadow-md transition cursor-pointer group flex flex-col h-full border border-transparent hover:border-primary/20"
                            @click="addToCart(product)"
                        >
                            <!-- Badges -->
                            <div v-if="product.lowStock" class="absolute top-2 right-2 z-10">
                                 <span class="bg-orange-500 text-white text-[10px] font-bold px-2 py-1 rounded">Low Ingredients</span>
                            </div>

                            <!-- Image -->
                            <div class="relative w-full aspect-square rounded-lg overflow-hidden mb-3 bg-gray-100">
                                <img 
                                    :src="product.image_url || '/no-image.jpg'" 
                                    :alt="product.name" 
                                    class="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                                    @error="$event.target.src = '/no-image.jpg'"
                                />

                                <!-- Logo Watermark -->
                                 <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition duration-300 bg-black/10">
                                    <PlusIcon class="w-8 h-8 text-white drop-shadow-md" />
                                 </div>
                            </div>

                            <!-- Info -->
                            <h3 class="font-bold text-gray-800 text-sm mb-1 line-clamp-2 leading-tight">{{ product.name }}</h3>
                            <p class="text-gray-500 text-sm mt-auto">{{ formatCurrency(product.price) }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Sidebar (Order/Cart) -->
            <aside 
                class="absolute inset-y-0 right-0 w-full lg:w-[400px] bg-white shadow-2xl z-20 flex flex-col shrink-0 transform transition-transform duration-300 border-l border-gray-100"
                :class="isCartOpen ? 'translate-x-0' : 'translate-x-full'"
            >
                <!-- Header (Mobile & Desktop) -->
                <div class="p-4 border-b flex justify-between items-center">
                    <h2 class="font-bold text-lg">Order Details</h2>
                    <button @click="isCartOpen = false" class="p-1 hover:bg-gray-100 rounded-full transition">
                        <XIcon class="w-6 h-6 text-gray-500" />
                    </button>
                </div>

                <!-- Inputs Area -->
                <div class="p-6 pb-2 space-y-4">
                    <!-- Customer Input -->
                    <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Customer Name</label>
                        <div class="relative">
                             <div v-if="selectedCustomer" class="flex items-center justify-between p-2.5 bg-green-50 border border-green-100 rounded-lg">
                                <div class="flex items-center gap-2 overflow-hidden">
                                    <div class="w-6 h-6 rounded-full bg-green-200 flex items-center justify-center text-green-700 text-xs font-bold">{{ selectedCustomer.name.charAt(0) }}</div>
                                    <div class="truncate">
                                        <p class="text-sm font-bold text-green-800 truncate">{{ selectedCustomer.name }}</p>
                                    </div>
                                </div>
                                <button @click="clearCustomer" class="text-gray-400 hover:text-red-500">
                                    <XIcon class="w-4 h-4" />
                                </button>
                            </div>
                            <input 
                                v-else
                                v-model="customerSearch"
                                @input="handleCustomerSearch"
                                class="w-full px-4 py-2.5 rounded-lg border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-colors" 
                                placeholder="Insert Customer Name" 
                                type="text"
                            />
                             <!-- Autocomplete Dropdown -->
                            <div v-if="customerSearch && !selectedCustomer" class="absolute left-0 right-0 mt-1 bg-white rounded-lg shadow-xl border border-gray-100 z-50 max-h-48 overflow-y-auto">
                                <ul class="py-1">
                                    <li v-if="customerSearchResults.length === 0" class="px-4 py-2 text-sm text-gray-500 italic">
                                        No members found
                                    </li>
                                    <!-- New Member Button -->
                                    <li class="border-b border-gray-100">
                                        <button 
                                            @click="isMemberModalOpen = true"
                                            class="w-full text-left px-4 py-3 hover:bg-green-50 text-sm font-bold text-primary flex items-center gap-2"
                                        >
                                            <div class="bg-primary/10 p-1 rounded-full"><PlusIcon class="w-4 h-4" /></div>
                                            Add New Member
                                        </button>
                                    </li>
                                    <li v-for="customer in customerSearchResults" :key="customer.id">
                                        <button 
                                            @click="selectCustomer(customer)"
                                            class="w-full text-left px-4 py-2 hover:bg-gray-50 text-sm flex justify-between items-center"
                                        >
                                            <span>{{ customer.name }}</span>
                                            <span class="text-xs text-green-600 bg-green-50 px-2 py-0.5 rounded-full" v-if="customer.phone">Member</span>
                                        </button>
                                    </li>
                                    <!-- Guest Option -->
                                    <li class="border-t border-gray-100">
                                        <button 
                                            @click="selectGuest(customerSearch)"
                                            class="w-full text-left px-4 py-2 hover:bg-gray-50 text-sm font-medium text-primary flex items-center justify-between"
                                        >
                                           <span>Use "{{ customerSearch }}" as Guest</span>
                                           <span class="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">Guest</span>
                                        </button>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    <!-- Order Type -->
                    <div>
                        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Order Type</label>
                        <div class="relative">
                            <select 
                                v-model="orderType"
                                class="w-full px-4 py-2.5 rounded-lg border border-gray-200 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none appearance-none cursor-pointer bg-white"
                            >
                                <option value="Dine In">Dine In</option>
                                <option value="Pickup Order">Pickup Order</option>
                            </select>
                            <ChevronDownIcon class="absolute right-4 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
                        </div>
                    </div>
                </div>

                <!-- Order List Header -->
                <div class="px-6 py-2">
                    <h2 class="text-lg font-bold text-gray-900 border-b border-gray-100 pb-2">Order Items</h2>
                </div>

                <!-- Cart Items -->
                <div class="flex-1 overflow-y-auto px-6 space-y-6">
                     <div v-if="cart.length === 0" class="flex flex-col items-center justify-center h-full text-gray-400 text-center">
                        <ShoppingBagIcon class="w-12 h-12 mb-3 text-gray-200" />
                        <p class="text-sm font-medium">Cart is empty</p>
                        <p class="text-xs mt-1">Add items to start an order</p>
                    </div>
                    
                    <div 
                        v-for="(item, index) in cart" 
                        :key="item.id" 
                        class="flex justify-between cross-start group cursor-pointer hover:bg-gray-50 p-2 rounded-lg transition"
                        @click="editCartItem(item)"
                    >
                         <div class="flex gap-4">
                            <span class="text-gray-400 font-medium text-sm w-4 pt-0.5">{{ index + 1 }}</span>
                            <div>
                                <h4 class="text-sm font-bold text-gray-800 leading-tight mb-1">{{ getProductName(item) }}</h4>
                                <div class="text-xs text-gray-500 space-y-0.5">
                                    <div v-if="getVisibleModifiers(item) && getVisibleModifiers(item).length > 0">
                                            <p v-for="(mod, mIndex) in getVisibleModifiers(item)" :key="mIndex">
                                            + {{ mod.option_name || mod.name }} 
                                        </p>
                                    </div>
                                    <p v-else>Standard</p>
                                    <p v-if="item.note" class="text-xs italic text-orange-600 mt-1">Note: {{ item.note }}</p>
                                    <p v-if="item.quantity > 1" class="font-bold text-primary">{{ item.quantity }}x @ {{ formatCurrency(item.unit_price || item.price) }}</p>
                                </div>
                            </div>
                         </div>
                         <div class="text-right">
                             <p class="text-sm font-bold text-gray-900">{{ formatCurrency((item.unit_price || item.price) * item.quantity) }}</p>
                             <!-- Controls Overlay or Inline -->
                             <div class="flex items-center gap-2 mt-2 justify-end">
                                <button @click.stop="updateQuantity(item, -1)" class="p-1 hover:bg-gray-100 rounded text-gray-600 bg-gray-100/50"><MinusIcon class="w-3 h-3" /></button>
                                 <button @click.stop="updateQuantity(item, 1)" class="p-1 hover:bg-gray-100 rounded text-gray-600 bg-gray-100/50"><PlusIcon class="w-3 h-3" /></button>
                                <button @click.stop="removeFromCart(item)" class="p-1 text-red-500 hover:bg-red-50 rounded"><Trash2Icon class="w-3 h-3" /></button>
                             </div>
                         </div>
                    </div>
                </div>

                 <!-- Footer Totals -->
                <div class="px-6 py-6 border-t border-gray-100 bg-white space-y-3 pb-8">
                     <!-- Discount Button -->
                    <button 
                        @click="isDiscountModalOpen = true"
                        class="w-full flex justify-between items-center px-4 py-3 border border-dashed border-gray-300 rounded-xl text-sm font-medium hover:text-primary hover:border-primary hover:bg-primary/5 transition"
                        :class="activeDiscount ? 'text-primary border-primary bg-primary/5' : 'text-gray-500'"
                    >
                        <span v-if="activeDiscount">Discount: {{ activeDiscount.name }}</span>
                        <span v-else>Add Discount</span>
                        <div class="flex items-center gap-2">
                            <span v-if="activeDiscount" class="font-bold">{{ formatCurrency(discountAmount) }}</span>
                            <ChevronRightIcon class="w-4 h-4" />
                        </div>
                    </button>

                    <div class="space-y-2 pt-2">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-500 font-medium">Sub Total</span>
                            <span class="font-bold text-gray-900">{{ formatCurrency(subTotal) }}</span>
                        </div>
                        <div v-if="discountAmount > 0" class="flex justify-between text-sm text-green-600">
                            <span class="font-medium">Discount</span>
                            <span class="font-bold">-{{ formatCurrency(discountAmount) }}</span>
                        </div>
                         <div class="flex justify-between text-sm">
                            <span class="text-gray-500 font-medium">Tax ({{ posStore.settings.tax_rate }}%)</span>
                            <span class="font-bold text-gray-900">{{ formatCurrency(tax) }}</span>
                        </div>
                         <div class="flex justify-between text-base pt-2">
                            <span class="font-bold text-gray-900">Total</span>
                            <span class="font-bold text-gray-900">{{ formatCurrency(grandTotal) }}</span>
                        </div>
                    </div>

                    <div class="flex gap-2">
                        <button 
                            class="px-4 bg-orange-500 hover:bg-orange-600 text-white font-bold py-3.5 rounded-xl shadow-lg shadow-orange-500/30 transition transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                            :disabled="cart.length === 0"
                            @click="handleOpenBill"
                            title="Open Bill"
                        >
                            <ReceiptIcon class="w-5 h-5" />
                        </button>
                        <button 
                            class="flex-1 bg-primary hover:bg-[#004d34] text-white font-bold py-3.5 rounded-xl shadow-lg shadow-primary/30 transition transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            :disabled="cart.length === 0"
                            @click="isPaymentModalOpen = true"
                        >
                            <CreditCardIcon class="w-5 h-5" />
                            Charge {{ formatCurrency(grandTotal) }}
                        </button>
                    </div>
                    
                    <button 
                        @click="isPendingBillsOpen = true"
                        class="w-full flex justify-between items-center px-4 py-3 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:text-primary hover:border-primary hover:bg-primary/5 transition mt-2 relative"
                    >
                        <span>View Pending Bills</span>
                        <div class="flex items-center gap-2">
                            <span v-if="pendingCount > 0" class="bg-red-500 text-white text-xs font-bold px-2 py-0.5 rounded-full animate-pulse">
                                {{ pendingCount }}
                            </span>
                            <ChevronRightIcon class="w-4 h-4" />
                        </div>
                    </button>
                </div>
            </aside>

            <!-- Floating Cart Button (All Screens if closed) -->
            <button 
                v-if="!isCartOpen"
                @click="isCartOpen = true"
                class="fixed bottom-6 right-6 p-4 rounded-full bg-primary text-white shadow-2xl z-30 flex items-center gap-2 hover:bg-[#004d34] transition"
            >
                <ShoppingBagIcon class="w-6 h-6" />
                <span class="font-bold hidden md:inline ml-1" v-if="cart.length > 0">{{ formatCurrency(grandTotal) }}</span>
                <span v-if="cart.length > 0" class="absolute -top-1 -right-1 bg-red-500 text-white text-xs w-5 h-5 rounded-full flex items-center justify-center border-2 border-white">{{ cart.length }}</span>
            </button>
        </div>

        <!-- Modals -->
        <PaymentModal 
            :is-open="isPaymentModalOpen"
            :total-amount="grandTotal"
            :loading="posStore.loading"
            @close="isPaymentModalOpen = false"
            @process="handlePayment"
        />

        <OrderSuccessModal 
            :is-open="isSuccessModalOpen"
            :order="lastOrder"
            @print="handlePrint(lastOrder)"
            @new-order="handleNewOrder"
        />

        <ShiftModal 
            :is-open="isShiftModalOpen"
            mode="start"
            :is-force="true"
            :loading="shiftLoading"
            @submit="handleShiftSubmit"
        />

        <PendingBillsModal 
            :is-open="isPendingBillsOpen"
            @close="isPendingBillsOpen = false"
            @load="handleLoadPendingBill"
            @cancel="handleCancelRequest"
            @print="handleProcessAndPrint"
        />

        <ManagerPinModal 
            :is-open="isManagerPinOpen"
            message="Enter manager PIN to cancel this order"
            :loading="cancelLoading"
            :error="cancelError"
            @close="isManagerPinOpen = false; orderToCancel = null; cancelError = ''"
            @submit="handleCancelConfirm"
        />

        <!-- Add Member Modal -->
        <MemberFormModal 
            :is-open="isMemberModalOpen"
            @close="isMemberModalOpen = false"
            @saved="handleNewMember"
        />

        <!-- Modifier Modal -->
        <ProductModifierModal 
            :is-open="isModifierModalOpen"
            :product="selectedProductForModifiers"
            :initial-selections="editingSelections"
            :initial-note="editingNote"
            @close="closeModifierModal"
            @confirm="handleAddWithModifiers"
        />

        <DiscountModal 
            :is-open="isDiscountModalOpen"
            @close="isDiscountModalOpen = false"
        />
    </PosLayout>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { debounce } from 'lodash';
import { 
    ChevronLeftIcon, SearchIcon, PlusIcon, MinusIcon, Trash2Icon, ChevronRightIcon, 
    ReceiptIcon, CreditCardIcon, XIcon, ChevronDownIcon, ShoppingBagIcon 
} from 'lucide-vue-next';
import { useProductDisplay } from '../../composables/useProductDisplay';

const { getProductName, getVisibleModifiers } = useProductDisplay();
import { usePosStore } from '../../stores/pos';
import PosLayout from '../../components/layout/PosLayout.vue';
import PaymentModal from '../../components/pos/PaymentModal.vue';
import OrderSuccessModal from '../../components/pos/OrderSuccessModal.vue';
import Receipt from '../../components/pos/Receipt.vue';
import ShiftModal from '../../components/pos/ShiftModal.vue';
import PendingBillsModal from '../../components/pos/PendingBillsModal.vue';
import ManagerPinModal from '../../components/pos/ManagerPinModal.vue';
import MemberFormModal from '../../components/pos/MemberFormModal.vue';
import ProductModifierModal from '../../components/pos/ProductModifierModal.vue';
import DiscountModal from '../../components/pos/DiscountModal.vue';
import { formatCurrency } from '../../utils/format';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';

const posStore = usePosStore();
const search = ref('');
const customerSearch = ref('');
const selectedCategoryId = ref(null);
const isCartOpen = ref(false);

// Modal States
const isPaymentModalOpen = ref(false);
const isSuccessModalOpen = ref(false);
const isShiftModalOpen = ref(false);
const isPendingBillsOpen = ref(false);
const isManagerPinOpen = ref(false);
const isMemberModalOpen = ref(false);
const isModifierModalOpen = ref(false);
const isDiscountModalOpen = ref(false);
const shiftLoading = ref(false);
const lastOrder = ref(null);
const orderToPrint = ref(null);
const selectedProductForModifiers = ref({});
const editingCartId = ref(null);
const editingSelections = ref({});
const editingNote = ref('');

// Open Bill / Cancellation State
const orderToCancel = ref(null);
const cancelError = ref('');
const cancelLoading = ref(false);
const toast = useToast();

const categories = computed(() => posStore.categories);
const products = computed(() => posStore.products);
const cart = computed(() => posStore.cart);
const subTotal = computed(() => posStore.subTotal);
const tax = computed(() => posStore.tax);
const grandTotal = computed(() => posStore.grandTotal);
const discountAmount = computed(() => posStore.discountAmount);
const activeDiscount = computed(() => posStore.activeDiscount);
const pendingCount = computed(() => posStore.pendingOrderCount);

const selectedCustomer = computed(() => posStore.selectedCustomer);
const customerSearchResults = computed(() => posStore.customers);
const orderType = computed({
    get: () => posStore.orderType,
    set: (val) => posStore.setOrderType(val)
});

// Actions
const loadProducts = () => {
    posStore.fetchProducts({
        category_id: selectedCategoryId.value,
        search: search.value
    });
};

const handlePayment = async (paymentDetails) => {
    try {
        // Auto-select guest if name typed but not selected
        if (!posStore.selectedCustomer && customerSearch.value) {
            selectGuest(customerSearch.value);
        }

        const response = await posStore.submitOrder(paymentDetails);
        
        // Success - posStore.submitOrder already returns unwrapped data
        lastOrder.value = {
            ...response,
            change: paymentDetails.change // Pass change info to success modal
        };
        isPaymentModalOpen.value = false;
        isSuccessModalOpen.value = true;
        
        posStore.clearCart();
        posStore.clearCustomer();
        // Keep orderType or reset? Usually keep.
        
    } catch (e) {
        alert(posStore.error || 'Payment Failed');
    }
};

const handleNewOrder = () => {
    isSuccessModalOpen.value = false;
    lastOrder.value = null;
    isCartOpen.value = false; // Reset view
};

const handlePrint = (order = null) => {
    // If order passed, set it as orderToPrint so Receipt component renders it
    if (order) {
        orderToPrint.value = order;
    } else if (lastOrder.value) {
        orderToPrint.value = lastOrder.value;
    }
    
    // Allow Vue to render the receipt first
    setTimeout(() => {
        window.print();
    }, 100);
};

const handleCustomerSearch = debounce(() => {
    posStore.searchCustomers(customerSearch.value);
}, 300);

const selectCustomer = (customer) => {
    posStore.selectCustomer(customer);
    customerSearch.value = ''; 
};

const selectGuest = (name) => {
    const guest = { id: null, name: name, points_balance: 0, is_guest: true };
    posStore.selectCustomer(guest); // Use posStore.selectCustomer to set the guest
    customerSearch.value = ''; // Clear the search input
};

const clearCustomer = () => {
    posStore.clearCustomer();
    customerSearch.value = '';
};

const handleCategoryClick = (category) => {
    if (category === null) {
        selectedCategoryId.value = null;
    } else {
        selectedCategoryId.value = category.id;
    }
    loadProducts();
};

const addToCart = (product) => {
    // Check for modifiers
    if (product.modifiers && product.modifiers.length > 0) {
        selectedProductForModifiers.value = product;
        editingCartId.value = null; // New item
        editingSelections.value = {};
        editingNote.value = '';
        isModifierModalOpen.value = true;
    } else {
        // No modifiers, add directly
        posStore.addToCart(product);
        isCartOpen.value = true;
    }
};

const editCartItem = (item) => {
    // Find original product to get modifier structure
    const product = posStore.products.find(p => p.id === item.id);
    if (!product) return;

    if (!product.modifiers || product.modifiers.length === 0) {
        // If product has no modifiers anymore, practically shouldn't happen or just ignore
        return; 
    }

    selectedProductForModifiers.value = product;
    editingCartId.value = item.cartId;
    editingNote.value = item.note || '';
    
    // Reconstruct selections from item.modifiers
    // item.modifiers is array of selected options
    // Need key-value/array object: { modId: optionObj or [optionObj] }
    const selections = {};
    if (item.modifiers) {
        item.modifiers.forEach(modItem => {
            // Find modifier definition to know type
            const modifierDef = product.modifiers.find(m => m.id == modItem.modifier_id);
            if (!modifierDef) return;

            // Reconstruct option object as expected by ProductModifierModal
            // It expects full option object, but we might only have saved details
            // We should find the full option from the product.modifiers options list
            const fullOption = modifierDef.options.find(opt => opt.id == modItem.option_id);
            
            if (fullOption) {
                 if (['single', 'radio', 'select'].includes(modifierDef.type)) {
                    selections[modifierDef.id] = fullOption;
                } else {
                    if (!selections[modifierDef.id]) selections[modifierDef.id] = [];
                    selections[modifierDef.id].push(fullOption);
                }
            }
        });
    }
    editingSelections.value = selections;
    isModifierModalOpen.value = true;
};

const closeModifierModal = () => {
    isModifierModalOpen.value = false;
    editingCartId.value = null;
    editingSelections.value = {};
    editingNote.value = '';
};

const handleAddWithModifiers = (data) => {
    const { product, modifiers, note } = data;
    
    // logic to remove old item if editing
    if (editingCartId.value) {
        // We can't easily "update" in place because cartId logic in store uses modifier hash
        // So valid strategy: Remove old cartId, Add new item with same quantity
        const oldItem = posStore.cart.find(i => i.cartId === editingCartId.value);
        const quantity = oldItem ? oldItem.quantity : 1;
        
        posStore.removeFromCart(editingCartId.value);
        
        posStore.addToCart(product, {
            modifiers: modifiers,
            note: note,
            quantity: quantity // Preserve quantity
        });
    } else {
        posStore.addToCart(product, {
            modifiers: modifiers,
            note: note
        });
    }

    isCartOpen.value = true;
    closeModifierModal(); // Reset editing state
};

const updateQuantity = (item, change) => {
    // Use item.cartId which is set in addToCart store action
    posStore.updateQuantity(item.cartId, item.quantity + change);
};

const removeFromCart = (item) => {
    posStore.removeFromCart(item.cartId);
};

const debouncedSearch = debounce(() => {
    loadProducts();
}, 300);

// Shift Management
const handleShiftSubmit = async (data) => {
    shiftLoading.value = true;
    try {
        await posStore.startShift(data.amount);
        isShiftModalOpen.value = false;
    } catch (e) {
        alert(e.message || 'Failed to start shift');
    } finally {
        shiftLoading.value = false;
    }
};

// Open Bill Handler
const handleOpenBill = async () => {
    if (cart.value.length === 0) return;
    
    // Validate Customer Name
    const name = selectedCustomer.value?.name || customerSearch.value;
    if (!name || name.trim() === '') {
        toast.warning('Please enter customer name first');
        return;
    }
    
    try {
        const payload = {
            items: cart.value.map(item => ({
                product_id: item.id,
                quantity: item.quantity,
                note: item.note || '',
                modifiers: item.modifiers || []
            })),
            customer_id: selectedCustomer.value?.id || null,
            customer_name: name,
            order_type: posStore.orderType.toLowerCase().replace(' ', '_'),
            payment_method: 'cash', // Default for open bill
            payment_status: 'pending' // Open Bill = Pending
        };

        const response = await api.post('/orders', payload);
        const orderData = response.data?.data || response.data || {};
        posStore.clearCart();
        posStore.clearCustomer();
        isCartOpen.value = false;
        toast.success(`Open Bill created: ${orderData.order_number || 'Unknown'}`);
    } catch (e) {
        toast.error(e.response?.data?.message || 'Failed to create open bill');
    }
};

// Load Pending Bill to Cart
const handleLoadPendingBill = (bill) => {
    // Clear current cart and customer
    posStore.clearCart();
    posStore.clearCustomer();
    posStore.setPendingOrder(bill.id);
    customerSearch.value = '';
    
    // Add items from bill to cart
    bill.items.forEach(item => {
        // Use product price as base price if available, otherwise fallback (risk of double counting if using unit_price)
        // Correct logic: passing modifiers will add to the price in addToCart
        const basePrice = item.product ? parseFloat(item.product.price) : parseFloat(item.unit_price); 
        
        const product = {
            id: item.product_id,
            name: item.product_name || item.product?.name || 'Unknown',
            price: basePrice, 
            image_url: item.product?.image_url
        };
        
        // Ensure modifiers is an array
        const modifiers = Array.isArray(item.modifiers) ? item.modifiers : [];

        posStore.addToCart(product, {
            quantity: item.quantity,
            modifiers: modifiers,
            note: item.note
        });
    });
    
    // Set customer - use customer relation or create object with original name
    if (bill.customer) {
        posStore.selectCustomer(bill.customer);
    } else if (bill.customer_name && bill.customer_name !== 'Guest' && bill.customer_name !== 'Walk-in') {
        // Preserve original customer name from the order as "selected customer"
        const guestCustomer = { 
            id: null, 
            name: bill.customer_name, 
            points_balance: 0, 
            is_guest: true 
        };
        posStore.selectCustomer(guestCustomer);
    } else if (bill.customer_name && bill.customer_name !== 'Guest') {
        // For Walk-in or other names, set it in the search field
        customerSearch.value = bill.customer_name;
    }
    
    isPendingBillsOpen.value = false;
    isCartOpen.value = true;
    toast.info(`Loaded bill: ${bill.order_number}`);
};

// Cancel Request - Show PIN Modal
const handleCancelRequest = (bill) => {
    orderToCancel.value = bill;
    cancelError.value = '';
    isPendingBillsOpen.value = false;
    isManagerPinOpen.value = true;
};

// Confirm Cancellation with PIN
const handleCancelConfirm = async (pin) => {
    if (!orderToCancel.value) return;
    
    cancelLoading.value = true;
    cancelError.value = '';
    
    try {
        await api.post(`/admin/orders/${orderToCancel.value.id}/cancel`, {
            manager_pin: pin
        });
        
        toast.success('Order cancelled successfully');
        isManagerPinOpen.value = false;
        orderToCancel.value = null;
        posStore.fetchPendingCount(); // Refresh count
    } catch (e) {
        cancelError.value = e.response?.data?.message || 'Invalid PIN or cancellation failed';
    } finally {
        cancelLoading.value = false;
    }
};

const handleProcessAndPrint = async (bill) => {
    try {
        // Mark as completed if not already
        if (bill.order_status !== 'completed') {
             await api.post(`/admin/orders/${bill.id}/process`);
        }
        
        // Print
        handlePrint(bill);
        toast.success(`Order ${bill.order_number} processed`);
        isPendingBillsOpen.value = false;
        
        // Refresh pending count
        posStore.fetchPendingCount();
        
    } catch (e) {
        toast.error('Failed to process order');
    }
};

const handleNewMember = (customer) => {
    posStore.selectCustomer(customer);
    toast.success(`Welcome, ${customer.name}!`);
};

watch(search, debouncedSearch);

onMounted(async () => {
    await Promise.all([
        posStore.fetchSettings(),
        posStore.fetchCategories(),
        loadProducts(),
        posStore.fetchCurrentShift()
    ]);
    
    // Check if shift is open
    if (!posStore.shift) {
        isShiftModalOpen.value = true;
    }
});
</script>
