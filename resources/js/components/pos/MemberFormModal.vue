<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="close"></div>
        <div class="bg-white rounded-3xl shadow-xl w-full max-w-md relative z-10 overflow-hidden animate-in zoom-in-95 duration-200">
            <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h2 class="text-xl font-bold text-gray-900">{{ isEditing ? 'Edit Member' : 'New Member' }}</h2>
                <button @click="close" class="p-1 rounded-full hover:bg-gray-200 text-gray-500 transition">
                    <XIcon class="w-5 h-5" />
                </button>
            </div>
            
            <form @submit.prevent="submit" class="p-6 space-y-5">
                <div>
                    <label class="block text-sm font-bold text-gray-700 mb-2">Full Name</label>
                    <input 
                        v-model="form.name" 
                        type="text" 
                        required 
                        class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition font-medium"
                        placeholder="John Doe"
                    >
                </div>

                <div>
                    <label class="block text-sm font-bold text-gray-700 mb-2">Phone Number</label>
                    <input 
                        v-model="form.phone" 
                        type="tel" 
                        required 
                        class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition font-medium"
                        placeholder="08123456789"
                    >
                </div>

                <div>
                    <label class="block text-sm font-bold text-gray-700 mb-2">Email <span class="text-gray-400 font-normal">(Optional)</span></label>
                    <input 
                        v-model="form.email" 
                        type="email" 
                        class="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition font-medium"
                        placeholder="john@example.com"
                    >
                </div>

                <div class="pt-4">
                    <button 
                        type="submit" 
                        class="w-full py-3.5 bg-primary hover:bg-[#004d34] text-white rounded-xl font-bold text-base shadow-lg shadow-primary/30 transition transform active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex justify-center items-center gap-2"
                        :disabled="loading"
                    >
                        <span v-if="loading" class="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                        {{ loading ? 'Saving...' : (isEditing ? 'Update Member' : 'Create Member') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, reactive, watch } from 'vue';
import { XIcon } from 'lucide-vue-next';
import api from '../../api/axios';
import { useToast } from 'vue-toastification';

const props = defineProps({
    isOpen: Boolean,
    customer: Object // If passed, edit mode
});

const emit = defineEmits(['close', 'saved']);

const toast = useToast();
const loading = ref(false);
const isEditing = ref(false);
const editId = ref(null);

const form = reactive({
    name: '',
    phone: '',
    email: ''
});

// Watch isOpen to reset/fill form
watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        if (props.customer) {
            isEditing.value = true;
            editId.value = props.customer.id;
            form.name = props.customer.name;
            form.phone = props.customer.phone;
            form.email = props.customer.email || '';
        } else {
            isEditing.value = false;
            editId.value = null;
            form.name = '';
            form.phone = '';
            form.email = '';
        }
    }
});

const close = () => {
    emit('close');
};

const submit = async () => {
    loading.value = true;
    try {
        let response;
        if (isEditing.value) {
            response = await api.put(`/admin/customers/${editId.value}`, form);
            toast.success('Member updated successfully');
        } else {
            response = await api.post('/admin/customers', form);
            toast.success('Member created successfully');
        }
        
        const savedCustomer = response.data?.data || response.data || {}; 
        close();
    } catch (e) {
        toast.error(e.response?.data?.message || 'Failed to save member');
    } finally {
        loading.value = false;
    }
};
</script>
