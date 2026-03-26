<template>
    <div class="fixed inset-0 w-full flex justify-center bg-white overflow-hidden font-sans">
        <div class="w-full max-w-md h-full flex flex-col relative">
        
        <!-- Sticky Header & Buttons -->
        <div class="absolute top-0 z-50 w-full pointer-events-none transition-all duration-300">
            <!-- Solid Background Layer -->
            <div class="absolute inset-0 bg-white shadow-sm transition-opacity duration-300" :style="{ opacity: headerOpacity }"></div>
            
            <div class="relative z-10 p-4 flex justify-between items-center">
                <button @click="$router.back()" 
                    class="flex w-10 h-10 items-center justify-center rounded-full transition-all active:scale-95 pointer-events-auto"
                    :class="headerOpacity > 0.8 ? 'bg-gray-100 text-gray-900 border-gray-200' : 'bg-black/20 backdrop-blur-md text-white border-white/10 hover:bg-black/30'">
                    <ChevronLeftIcon class="w-6 h-6" />
                </button>
                
                <!-- Sticky Title -->
                <span class="font-bold text-lg text-gray-900 absolute left-1/2 -translate-x-1/2 transition-all duration-300 transform translate-y-4 opacity-0 truncate max-w-[50%]"
                      :class="{ 'translate-y-0! opacity-100!': headerOpacity > 0.8 }">
                    {{ displayProductName }}
                </span>

                <button @click="toggleFavorite" class="flex w-10 h-10 items-center justify-center rounded-full transition-all active:scale-95 pointer-events-auto group"
                    :class="headerOpacity > 0.8 ? 'bg-gray-100 text-gray-900 border-gray-200' : 'bg-black/20 backdrop-blur-md text-white border-white/10 hover:bg-black/30'">
                    <HeartIcon class="w-6 h-6 transition-colors" :class="{ 'fill-current text-red-500': isFavorite, 'group-hover:text-red-500': !isFavorite }" />
                </button>
            </div>
        </div>

        <!-- Scroll Container -->
        <div ref="scrollContainer" @scroll="handleScroll" class="flex-1 overflow-y-auto relative bg-white scroll-smooth shadow-2xl [&::-webkit-scrollbar]:hidden">
            
            <!-- Sticky Hero Image (Parallax) -->
            <div class="sticky top-0 w-full h-96 z-0 shrink-0 overflow-hidden">
                <div v-if="product" class="absolute inset-0 bg-cover bg-center transition-transform duration-75 ease-out" 
                     :style="`background-image: url('${product.image_url || '/no-image.jpg'}'); transform: scale(${1 + scrollProgress * 0.1}) translateY(${scrollProgress * 30}px);`"></div>
                <div v-else class="absolute inset-0 bg-gray-200 animate-pulse"></div>
                <!-- Gradient Overlay -->
                <div class="absolute inset-0 bg-linear-to-b from-black/30 via-transparent to-black/10" :style="{ opacity: 1 - headerOpacity }"></div>
            </div>

            <!-- Content Sheet -->
            <div v-if="product" class="relative z-10 bg-white rounded-t-[2.5rem] min-h-[calc(100dvh-19rem)] -mt-20 shadow-[0_-10px_40px_rgba(0,0,0,0.1)] flex flex-col overflow-hidden">

                <!-- Drag Handle -->
                <div class="flex justify-center pt-3 pb-1 opacity-50">
                    <div class="w-12 h-1.5 bg-gray-300 rounded-full"></div>
                </div>

                <div class="px-6 py-6 flex-1 flex flex-col pb-32">
                    <!-- Title & Price -->
                    <div class="flex flex-col gap-2 pb-6">
                        <h1 class="text-2xl font-bold tracking-tight text-gray-900 leading-tight transition-all duration-300">{{ displayProductName }}</h1>
                        <span class="text-2xl font-bold text-primary">Rp {{ formatNumber(store.resolveProductPrice(product)) }}</span>
                        <p class="text-sm text-gray-500 font-medium leading-relaxed mt-1">
                            {{ product.description || 'No description available.' }}
                        </p>
                    </div>
                    
                    <!-- Main Section Divider -->
                    <div v-if="visibleModifiers && visibleModifiers.length > 0" class="h-2 bg-gray-100 -mx-6 mb-6"></div>

                    <!-- Dynamic Modifiers -->
                    <template v-for="(modifier, index) in visibleModifiers" :key="modifier.id">
                        <!-- Divider between modifiers -->
                        <template v-if="index > 0">
                            <div v-if="['Available', 'Size'].some(n => modifier.name.includes(n))" class="border-b border-dashed border-gray-200 -mx-6 mb-6 mt-2"></div>
                            <div v-else class="h-2 bg-gray-100 -mx-6 mb-6 mt-2"></div>
                        </template>
                        
                        <!-- Radio Modifier -->
                        <div v-if="modifier.type === 'radio'" class="flex flex-col gap-3">
                        <!-- Header & Required Badge -->
                        <div class="flex items-center justify-between">
                            <h3 class="text-lg font-bold text-gray-900">{{ modifier.name }}</h3>
                            <span v-if="modifier.is_required && !['Size', 'Sweetness', 'Sugar'].some(n => modifier.name.includes(n))" class="text-xs font-medium text-gray-400">Wajib, Pilih 1</span>
                            <span v-else-if="modifier.is_required" class="text-xs font-normal text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full">Required</span>
                        </div>

                            <!-- Case 1: Has Icons (Iced / Hot) -> Split Switcher -->
                            <div v-if="modifier.options.some(o => o.icon)" class="flex gap-4 mt-3">
                                <label v-for="option in modifier.options" :key="option.id" class="cursor-pointer group" :class="modifier.options.length === 1 ? 'w-[calc(50%-0.5rem)] flex-none' : 'flex-1'">
                                    <input v-model="selectedModifiers[modifier.id]" class="peer sr-only" :name="`modifier_${modifier.id}`" type="radio" :value="option.id"/>
                                    <div class="flex items-center justify-center gap-2 py-3 rounded-full text-base font-bold border transition-all duration-200
                                        border-gray-200 text-gray-500 hover:border-gray-300 bg-white
                                        peer-checked:border-primary peer-checked:bg-primary/5 peer-checked:text-primary">
                                        <component :is="getIcon(option.icon)" class="w-5 h-5" v-if="option.icon && getIcon(option.icon)" stroke-width="2.5" />
                                        <span>{{ option.name }}</span>
                                        <span v-if="parseFloat(option.price) > 0" class="text-xs font-normal opacity-80">(+{{ formatNumber(option.price) }})</span>
                                    </div>
                                </label>
                            </div>

                            <!-- Case 2: Size (Segmented) or Sweetness (Buttons) -->
                            <div v-else-if="['Size', 'Sweetness', 'Sugar'].some(n => modifier.name.includes(n))" class="mt-3">
                                
                                <!-- Subcase 2A: Size -> Segmented -->
                                <div v-if="modifier.name.includes('Size')" class="bg-gray-100 p-1.5 rounded-xl flex">
                                    <label v-for="option in modifier.options" :key="option.id" class="relative flex-1 cursor-pointer group">
                                        <input v-model="selectedModifiers[modifier.id]" class="peer sr-only" :name="`modifier_${modifier.id}`" type="radio" :value="option.id"/>
                                        <div class="flex items-center justify-center gap-1.5 py-2.5 rounded-lg text-sm font-semibold transition-all duration-200 text-gray-500 hover:text-gray-900 peer-checked:bg-white peer-checked:text-primary peer-checked:shadow-sm">
                                            <span>{{ option.name }}</span>
                                            <span v-if="store.resolveModifierPrice(option) > 0" class="text-xs font-medium opacity-80">(+{{ formatNumber(store.resolveModifierPrice(option)) }})</span>
                                        </div>
                                    </label>
                                </div>
                                
                                <!-- Subcase 2B: Sweetness/Sugar -> Buttons -->
                                <div v-else class="flex flex-wrap gap-3">
                                     <label v-for="option in modifier.options" :key="option.id" class="relative cursor-pointer group min-w-[30%] flex-1">
                                        <input v-model="selectedModifiers[modifier.id]" class="peer sr-only" :name="`modifier_${modifier.id}`" type="radio" :value="option.id"/>
                                        <div class="px-4 py-3 rounded-xl text-sm font-semibold border transition-all text-center
                                            border-gray-200 text-gray-600 bg-white hover:border-gray-300
                                            peer-checked:border-primary peer-checked:bg-primary/5 peer-checked:text-primary">
                                            {{ option.name }}
                                            <span v-if="store.resolveModifierPrice(option) > 0" class="text-xs block opacity-80">+{{ formatNumber(store.resolveModifierPrice(option)) }}</span>
                                        </div>
                                    </label>
                                </div>
                            </div>

                            <!-- Case 3: List Style (New Default) -->
                            <div v-else class="flex flex-col mt-1">
                                <label v-for="option in modifier.options" :key="option.id" class="relative cursor-pointer group flex items-center justify-between py-4 border-b border-dashed border-gray-100 last:border-0 hover:bg-gray-50/50 -mx-2 px-2 rounded-lg transition-colors">
                                    <div class="font-medium text-gray-900 text-base">
                                        {{ option.name }}
                                    </div>
                                    <div class="flex items-center gap-3">
                                        <span v-if="store.resolveModifierPrice(option) > 0" class="text-sm font-medium text-gray-500">+Rp {{ formatNumber(store.resolveModifierPrice(option)) }}</span>
                                        
                                        <!-- Custom Radio Circle -->
                                        <div class="relative flex items-center justify-center w-6 h-6">
                                            <input v-model="selectedModifiers[modifier.id]" class="peer sr-only" :name="`modifier_${modifier.id}`" type="radio" :value="option.id"/>
                                            <div class="w-5 h-5 rounded-full border-2 border-gray-300 transition-colors peer-checked:border-primary peer-checked:bg-white"></div>
                                            <div class="absolute w-2.5 h-2.5 rounded-full bg-primary scale-0 peer-checked:scale-100 transition-transform"></div>
                                        </div>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <!-- Checkbox Modifier -->
                        <div v-else-if="modifier.type === 'checkbox'" class="flex flex-col gap-3">
                            <h3 class="text-lg font-bold text-gray-900">{{ modifier.name }}</h3>
                            <div class="flex flex-col gap-2">
                                <label v-for="option in modifier.options" :key="option.id" class="flex items-center justify-between p-3 rounded-xl border border-gray-100 bg-gray-50/50 cursor-pointer transition-colors hover:border-primary/30 has-checked:border-primary has-checked:bg-primary/5">
                                    <div class="flex items-center gap-3">
                                        <input v-model="selectedModifiers[modifier.id]" class="w-5 h-5 rounded border-gray-300 text-primary focus:ring-primary/20 accent-primary" type="checkbox" :value="option.id"/>
                                        <span class="text-sm font-medium text-gray-700">{{ option.name }}</span>
                                    </div>
                                    <span v-if="store.resolveModifierPrice(option) > 0" class="text-sm font-semibold text-primary">+Rp {{ formatNumber(store.resolveModifierPrice(option)) }}</span>
                                </label>
                            </div>
                        </div>
                    </template>

                    <!-- No modifiers fallback removed. Will just show name, price, and description. -->
                </div>
            </div>
        </div>

        <!-- Fixed Footer -->
        <div class="flex-none w-full z-50">
             <!-- Points Banner -->
             <div class="bg-[#fcfdf5] border-t border-[#e8eddf] py-2.5 px-4 flex items-center gap-2 justify-start">
                 <img src="/point.png" class="w-5 h-5 object-contain" alt="Point" />
                 <span class="text-xs font-bold text-[#3f4d25]">Kamu berpotensi mendapatkan 2 Poin</span>
             </div>

             <div class="bg-white border-t border-gray-100 p-4 pb-safe shadow-[0_-4px_30px_rgba(0,0,0,0.08)]">
                <div class="flex items-center gap-4">
                    <div class="flex items-center gap-3 bg-gray-50 rounded-xl px-4 py-2 border border-gray-100 h-14 w-32 justify-between">
                        <button @click="quantity > 1 ? quantity-- : null" class="w-8 h-8 flex items-center justify-center rounded-full bg-white shadow-sm border border-gray-100 text-gray-600 hover:text-primary transition-all disabled:opacity-50 active:scale-95" :disabled="quantity <= 1">
                            <MinusIcon class="w-4 h-4" />
                        </button>
                        <span class="text-lg font-bold text-gray-900">{{ quantity }}</span>
                        <button @click="quantity++" class="w-8 h-8 flex items-center justify-center rounded-full bg-white shadow-sm border border-gray-100 text-gray-600 hover:text-primary transition-all active:scale-95">
                            <PlusIcon class="w-4 h-4" />
                        </button>
                    </div>
                    <button @click="addToCart" class="flex-1 h-14 bg-[#5a6c37] text-white rounded-xl flex items-center justify-between px-6 font-bold shadow-lg shadow-[#5a6c37]/25 active:scale-[0.98] transition-all hover:bg-[#4a5c2e]">
                        <span>{{ isEditing ? 'Update' : 'Add' }} - </span>
                        <span>Rp {{ formatNumber(totalPrice) }}</span>
                    </button>
                </div>
            </div>
        </div>
        <AddToCartModal 
            :is-open="showSuccessModal"
            :item="addedItem"
            :product="product"
            @continue="handleContinueShopping"
            @view-cart="handleViewCart"
            @update-item="handleUpdateItem"
        />
        </div>
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ChevronLeftIcon, HeartIcon, PlusIcon, MinusIcon, CoffeeIcon, GlassWaterIcon } from 'lucide-vue-next';
import { useToast } from 'vue-toastification';
import { useCustomerStore } from '../../stores/customer';
import AddToCartModal from '../../components/customer/AddToCartModal.vue';

const iconMap = {
    'coffee': CoffeeIcon,
    'glass-water': GlassWaterIcon
};

const getIcon = (name) => iconMap[name] || null;

const router = useRouter();
const route = useRoute();
const toast = useToast();
const store = useCustomerStore();

const product = ref(null);
const loading = ref(true);
const quantity = ref(1);
const showSuccessModal = ref(false);
const addedItem = ref(null);
const addedCartId = ref(null);
const selectedModifiers = reactive({}); 
const isEditing = computed(() => !!route.query.cartId);
const scrollContainer = ref(null);
const scrollProgress = ref(0);
const headerOpacity = ref(0);

const handleScroll = (e) => {
    const scrollTop = e.target.scrollTop;
    const maxScroll = 250; 
    const progress = Math.min(scrollTop / maxScroll, 1);
    
    scrollProgress.value = progress;
    headerOpacity.value = progress;
};



const formatNumber = (num) => new Intl.NumberFormat('id-ID').format(num);

// Initialize selectedModifiers when product loads
watch(() => product.value, (newProduct) => {
    if (newProduct && newProduct.modifiers) {
        newProduct.modifiers.forEach(modifier => {
            if (modifier.type === 'radio' && modifier.options.length > 0) {
                // For radio, default to first option
                selectedModifiers[modifier.id] = modifier.options[0].id;
            } else if (modifier.type === 'checkbox') {
                // For checkbox, start with empty array
                selectedModifiers[modifier.id] = [];
            }
        });
    }
}, { immediate: true });

const displayProductName = computed(() => {
    if (!product.value) return '';
    let name = product.value.name;
    let prefixes = [];
    let suffixes = [];

    if (product.value.modifiers) {
        product.value.modifiers.forEach(mod => {
            const selection = selectedModifiers[mod.id];
            if (mod.type === 'radio' && selection) {
                const opt = mod.options.find(o => o.id === selection);
                if (opt) {
                    if (opt.name_prefix) prefixes.push(opt.name_prefix);
                    if (opt.name_suffix) suffixes.push(opt.name_suffix);
                }
            }
        });
    }

    if (prefixes.length > 0) name = prefixes.join(' ') + ' ' + name;
    if (suffixes.length > 0) name = name + ' ' + suffixes.join(' ');
    
    return name;
});

const visibleModifiers = computed(() => {
    if (!product.value || !product.value.modifiers) return [];
    
    return product.value.modifiers
        .filter(mod => {
            const pivot = mod.pivot || {};
            const condModId = pivot.condition_modifier_id;
            const condOptId = pivot.condition_option_id;
            
            if (!condModId) return true;
            
            const currentSelection = selectedModifiers[condModId];
            if (!currentSelection) return false;
            
            if (condOptId) {
                 if (Array.isArray(currentSelection)) {
                     return currentSelection.includes(condOptId);
                 } else {
                     return currentSelection == condOptId;
                 }
            }
            return true;
        })
        .map(mod => {
            const pivot = mod.pivot || {};
            let allowed = pivot.allowed_options;
            if (typeof allowed === 'string') {
                try { allowed = JSON.parse(allowed); } catch(e) { allowed = null; }
            }
            
            if (!allowed) return mod;

            return {
                ...mod,
                options: mod.options.filter(opt => allowed.includes(opt.id))
            };
        })
        .filter(mod => mod.options.length > 0)
        .sort((a, b) => {
            const getRank = (name) => {
                 if (name === 'Available') return 1;
                 if (name === 'Size') return 2;
                 return 10;
            };
            return getRank(a.name) - getRank(b.name);
        });
});


const totalPrice = computed(() => {
    if (!product.value) return 0;
    let base = parseFloat(store.resolveProductPrice(product.value));
    
    // If product has dynamic modifiers, calculate from selectedModifiers
    if (product.value.modifiers && product.value.modifiers.length > 0) {
        product.value.modifiers.forEach(modifier => {
            const selection = selectedModifiers[modifier.id];
            if (modifier.type === 'radio' && selection) {
                const option = modifier.options.find(o => o.id === selection);
                if (option) base += parseFloat(store.resolveModifierPrice(option)) || 0;
            } else if (modifier.type === 'checkbox' && Array.isArray(selection)) {
                selection.forEach(optId => {
                    const option = modifier.options.find(o => o.id === optId);
                    if (option) base += parseFloat(store.resolveModifierPrice(option)) || 0;
                });
            }
        });
    }
    
    return base * quantity.value;
});

const addToCart = () => {
    if (!product.value) return;
    
    // Build modifiers snapshot for order item
    let modifiersSnapshot = [];
    if (product.value.modifiers && product.value.modifiers.length > 0) {
        product.value.modifiers.forEach(modifier => {
            const selection = selectedModifiers[modifier.id];
            if (modifier.type === 'radio' && selection) {
                const option = modifier.options.find(o => o.id === selection);
                if (option) {
                    // Store the whole option object so store can re-resolve price if order type changes
                    modifiersSnapshot.push({
                        ...option,
                        modifier_id: modifier.id,
                        modifier_name: modifier.name,
                        option_id: option.id, // for consistency
                        option_name: option.name, // for consistency
                        price: store.resolveModifierPrice(option),
                        is_default: modifier.options[0].id === option.id
                    });
                }
            } else if (modifier.type === 'checkbox' && Array.isArray(selection)) {
                selection.forEach(optId => {
                    const option = modifier.options.find(o => o.id === optId);
                    if (option) {
                        modifiersSnapshot.push({
                            ...option,
                            modifier_id: modifier.id,
                            modifier_name: modifier.name,
                            option_id: option.id,
                            option_name: option.name,
                            price: store.resolveModifierPrice(option)
                        });
                    }
                });
            }
        });
    }
    
    const newCartId = store.addToCart(product.value, {
        quantity: quantity.value,
        modifiers: modifiersSnapshot
    });

    if (isEditing.value && route.query.cartId && route.query.cartId !== newCartId) {
        store.removeFromCart(route.query.cartId);
    } else if (isEditing.value && route.query.cartId === newCartId) {
        const item = store.cart.find(i => i.cartId === newCartId);
        if (item) item.quantity = quantity.value;
    }
    
    addedCartId.value = newCartId;
    
    // Construct item for modal display
    addedItem.value = {
        ...product.value,
        quantity: quantity.value,
        modifiers: modifiersSnapshot
    };
    
    showSuccessModal.value = true;
};

const handleUpdateItem = (suggestion) => {
    if (!product.value) return;

    const modId = suggestion.modifier_id;
    const modifier = product.value.modifiers.find(m => m.id === modId);
    
    if (modifier) {
        if (modifier.type === 'radio') {
            selectedModifiers[modId] = suggestion.id;
        } else if (modifier.type === 'checkbox') {
             if (!selectedModifiers[modId]) selectedModifiers[modId] = [];
             if (!Array.isArray(selectedModifiers[modId])) selectedModifiers[modId] = [];
             
             if (!selectedModifiers[modId].includes(suggestion.id)) {
                 selectedModifiers[modId].push(suggestion.id);
             }
        }
    }

    if (addedCartId.value) {
        store.removeFromCart(addedCartId.value);
    }

    addToCart();
};

const handleContinueShopping = () => {
    showSuccessModal.value = false;
    router.back();
};

const handleViewCart = () => {
    showSuccessModal.value = false;
    router.push('/checkout');
};

onMounted(async () => {
    const id = route.params.id;
    const cartId = route.query.cartId;

    if (id) {
        product.value = await store.fetchProduct(id);
        
        // Populate if editing
        if (cartId) {
            const item = store.cart.find(i => i.cartId === cartId);
            if (item) {
                quantity.value = item.quantity;
                if (item.modifiers) {
                    item.modifiers.forEach(mod => {
                        const productMod = product.value.modifiers?.find(m => m.id === mod.modifier_id);
                        if (productMod) {
                            if (productMod.type === 'radio') {
                                selectedModifiers[mod.modifier_id] = mod.option_id;
                            } else {
                                if (!selectedModifiers[mod.modifier_id]) selectedModifiers[mod.modifier_id] = [];
                                if (!selectedModifiers[mod.modifier_id].includes(mod.option_id)) {
                                    selectedModifiers[mod.modifier_id].push(mod.option_id);
                                }
                            }
                        }
                    });
                }
            }
        }
    }
    loading.value = false;
});

const isFavorite = computed(() => {
    if (!product.value) return false;
    return store.favorites.some(f => f.id === product.value.id);
});

const toggleFavorite = () => {
    if (product.value) {
        store.toggleFavorite(product.value);
    }
};
</script>

<style scoped>
.pb-safe {
    padding-bottom: max(env(safe-area-inset-bottom), 5px);
}
</style>
