<template>
    <MainLayout :loading="pageLoading">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Employee Management</h1>
                <p class="text-gray-500">Manage staff access and roles.</p>
            </div>
            <button @click="openModal()" class="bg-primary hover:bg-green-800 text-white px-4 py-2 rounded-lg font-bold flex items-center transition-colors shadow-lg w-full md:w-auto justify-center">
                <PlusIcon class="w-5 h-5 mr-2" />
                Add Employee
            </button>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
             <!-- Search -->
             <div class="p-6 border-b border-gray-100 bg-gray-50/50">
                 <div class="relative w-full md:w-96">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-3">
                        <SearchIcon class="w-5 h-5 text-gray-400" />
                    </span>
                    <input 
                        v-model="search" 
                        @input="debouncedSearch"
                        type="text" 
                        placeholder="Search name or email..." 
                        class="pl-10 border-gray-300 rounded-xl text-sm focus:ring-primary focus:border-primary w-full py-2 shadow-sm"
                    >
                 </div>
             </div>

            <div class="overflow-x-auto">
                <table class="w-full text-left whitespace-nowrap">
                    <thead class="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider border-b border-gray-100">
                        <tr>
                            <th class="px-6 py-4 font-semibold">Name</th>
                            <th class="px-6 py-4 font-semibold">Email</th>
                            <th class="px-6 py-4 font-semibold">Role</th>
                            <th class="px-6 py-4 font-semibold">Joined Date</th>
                            <th class="px-6 py-4 font-semibold text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 text-sm">
                        <tr v-for="user in (users.data || []).filter(u => u != null)" :key="user.id" class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 font-bold text-slate-800">{{ user.name }}</td>
                            <td class="px-6 py-4 text-gray-600">{{ user.email }}</td>
                            <td class="px-6 py-4">
                                <span class="px-2 py-1 rounded-full text-xs font-bold capitalize bg-blue-100 text-blue-700">
                                    {{ user.roles[0]?.name?.replace('_', ' ') || 'No Role' }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-gray-500">{{ new Date(user.created_at).toLocaleDateString() }}</td>
                            <td class="px-6 py-4 text-right space-x-2">
                                <button @click="openModal(user)" class="text-blue-600 hover:text-blue-800 font-medium text-sm hover:underline">Edit</button>
                                <button 
                                    v-if="user.email !== authUser?.email"
                                    @click="deleteUser(user)" 
                                    class="text-red-500 hover:text-red-700 font-medium text-sm hover:underline"
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                        <tr v-if="users.data?.length === 0">
                            <td colspan="5" class="px-6 py-12 text-center text-gray-400">No employees found</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Create/Edit Modal -->
        <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeModal"></div>
            <div class="bg-white rounded-2xl shadow-xl w-full max-w-md relative z-10 overflow-hidden">
                <div class="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
                    <h2 class="text-xl font-bold text-slate-800">{{ isEditing ? 'Edit Employee' : 'Add Employee' }}</h2>
                    <button @click="closeModal" class="text-gray-400 hover:text-gray-600"><XIcon class="w-6 h-6" /></button>
                </div>
                
                <form @submit.prevent="submitForm" class="p-6 space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                        <input v-model="form.name" type="text" required class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input v-model="form.email" type="email" required class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">No Whatsapp</label>
                        <input v-model="form.no_whatsapp" type="tel" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3" placeholder="6281234567899">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Password <span v-if="isEditing" class="text-gray-400 text-xs font-normal">(Leave blank to keep current)</span></label>
                        <input v-model="form.password" type="password" :required="!isEditing" class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Role</label>
                        <select v-model="form.role" required class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3 bg-white">
                            <option value="cashier">Cashier</option>
                            <option value="store_manager">Store Manager</option>
                            <option value="super_admin">Super Admin</option>
                        </select>
                    </div>
                    
                    <div v-if="form.role === 'store_manager'">
                        <label class="block text-sm font-medium text-gray-700 mb-1">Manager PIN Code</label>
                        <input 
                            v-model="form.pin_code" 
                            type="text" 
                            pattern="\d*" 
                            maxlength="6" 
                            placeholder="4-6 digit PIN"
                            class="w-full border border-gray-300 rounded-lg focus:ring-primary focus:border-primary py-2.5 px-3"
                            required
                        >
                        <p class="text-xs text-gray-500 mt-1">Required for overriding operations (voids, cancellations)</p>
                    </div>

                    <div class="pt-4 flex justify-end space-x-3">
                        <button type="button" @click="closeModal" class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 font-medium">Cancel</button>
                        <button type="submit" :disabled="formLoading" class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-green-800 font-bold disabled:opacity-50">
                            {{ formLoading ? 'Saving...' : 'Save Employee' }}
                        </button>
                    </div>
                </form>
            </div>
        </div>

    </MainLayout>
</template>

<script setup>
import { ref, onMounted, reactive, computed } from 'vue';
import MainLayout from '../../../components/layout/MainLayout.vue';
import { SearchIcon, PlusIcon, XIcon } from 'lucide-vue-next';
import api from '../../../api/axios';
import { useToast } from "vue-toastification";
import { useAuthStore } from '../../../stores/auth';

const toast = useToast();
const authStore = useAuthStore();
const authUser = computed(() => authStore.user);

const users = ref({ data: [] });
const search = ref('');
const pageLoading = ref(true);
const showModal = ref(false);
const isEditing = ref(false);
const formLoading = ref(false);

const form = reactive({
    id: null,
    name: '',
    email: '',
    no_whatsapp: '',
    password: '',
    role: 'cashier',
    pin_code: ''
});

const fetchUsers = async (page = 1) => {
    try {
        const response = await api.get('/admin/users', {
            params: { page, search: search.value }
        });
        users.value = response.data?.data || response.data || {};
    } catch (error) {
        console.error("Fetch users failed", error);
    } finally {
        pageLoading.value = false;
    }
};

let debounceTimeout = null;
const debouncedSearch = () => {
    if (debounceTimeout) clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => {
        fetchUsers(1);
    }, 300);
};

const openModal = (user = null) => {
    if (user) {
        isEditing.value = true;
        form.id = user.id;
        form.name = user.name;
        form.email = user.email;
        form.no_whatsapp = user.no_whatsapp || '';
        // form.password = ''; // Don't reset password field
        form.role = user.roles && user.roles.length ? user.roles[0].name : 'cashier';
        form.pin_code = user.pin_code || '';
    } else {
        isEditing.value = false;
        form.id = null;
        form.name = '';
        form.email = '';
        form.no_whatsapp = '';
        form.password = '';
        form.role = 'cashier';
        form.pin_code = ''; // Reset PIN
    }
    showModal.value = true;
};

const closeModal = () => {
    showModal.value = false;
};

const submitForm = async () => {
    formLoading.value = true;
    try {
        const payload = { ...form };
        if (isEditing.value && !payload.password) delete payload.password;

        if (isEditing.value) {
            await api.put(`/admin/users/${form.id}`, payload);
            toast.success("Employee updated successfully");
            
            // If editing self, refresh auth store
            if (form.id === authStore.user?.id) {
                await authStore.fetchUser();
            }
        } else {
            await api.post('/admin/users', payload);
            toast.success("Employee created successfully");
        }
        closeModal();
        fetchUsers();
    } catch (error) {
        toast.error("Failed to save employee. Check input.");
        console.error(error);
    } finally {
        formLoading.value = false;
    }
};

const deleteUser = async (user) => {
    if (!confirm(`Delete ${user.name}? This cannot be undone.`)) return;
    try {
        await api.delete(`/admin/users/${user.id}`);
        toast.success("Employee deleted");
        fetchUsers();
    } catch (error) {
        toast.error("Failed to delete employee");
    }
};

onMounted(() => {
    fetchUsers();
});
</script>
