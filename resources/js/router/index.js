import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../stores/auth';
import { useMemberAuthStore } from '../stores/memberAuth';

// Import Views
import Login from '../views/auth/Login.vue';
import AdminDashboard from '../views/admin/Dashboard.vue';
import Cashier from '../views/pos/Cashier.vue';

const routes = [
    {
        path: '/login',
        name: 'Login',
        component: Login,
        meta: { guest: true }
    },
    {
        path: '/admin',
        name: 'AdminDashboard',
        component: AdminDashboard,
        component: AdminDashboard,
        meta: { requiresAuth: true, role: 'super_admin', title: 'Dashboard' }
    },
    {
        path: '/admin/orders',
        name: 'Orders',
        component: () => import('../views/admin/orders/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Transactions' }
    },
    {
        path: '/admin/users',
        name: 'Users',
        component: () => import('../views/admin/users/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'User Management' }
    },
    {
        path: '/admin/shifts',
        name: 'Shifts',
        component: () => import('../views/admin/shifts/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Shift Management' }
    },
    {
        path: '/admin/discounts',
        name: 'Discounts',
        component: () => import('../views/admin/discounts/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Discounts' }
    },
    {
        path: '/admin/suppliers',
        name: 'Suppliers',
        component: () => import('../views/admin/suppliers/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Suppliers' }
    },
    {
        path: '/admin/audit-logs',
        name: 'AuditLogs',
        component: () => import('../views/admin/audit-logs/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Audit Logs' }
    },
    // Catalog Management
    {
        path: '/admin/categories',
        name: 'Categories',
        component: () => import('../views/admin/categories/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Categories' }
    },
    {
        path: '/admin/modifiers',
        name: 'Modifiers',
        component: () => import('../views/admin/modifiers/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Modifiers' }
    },
    {
        path: '/admin/products',
        name: 'Products',
        component: () => import('../views/admin/products/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Products' }
    },
    {
        path: '/admin/products/create',
        name: 'ProductCreate',
        component: () => import('../views/admin/products/Form.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Add Product' }
    },
    {
        path: '/admin/products/:id/edit',
        name: 'ProductEdit',
        component: () => import('../views/admin/products/Form.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Edit Product' }
    },
    {
        path: '/admin/products/:id/edit',
        name: 'ProductEdit',
        component: () => import('../views/admin/products/Form.vue'),
        meta: { requiresAuth: true, role: 'super_admin' }
    },
    {
        path: '/admin/inventory',
        name: 'Inventory',
        component: () => import('../views/admin/inventory/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Inventory' }
    },
    {
        path: '/admin/banners',
        name: 'Banners',
        component: () => import('../views/admin/banners/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Banners' }
    },
    {
        path: '/admin/settings',
        name: 'Settings',
        component: () => import('../views/admin/settings/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Settings' }
    },
    {
        path: '/admin/reports',
        name: 'Reports',
        component: () => import('../views/admin/reports/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Reports' }
    },
    {
        path: '/admin/customers',
        name: 'Customers',
        component: () => import('../views/admin/customers/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Customers' }
    },
    {
        path: '/admin/customers/:id',
        name: 'CustomerShow',
        component: () => import('../views/admin/customers/Show.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Customer Details' }
    },
    {
        path: '/pos/dashboard',
        name: 'PosDashboard',
        component: () => import('../views/pos/Dashboard.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'POS Dashboard' }
    },
    {
        path: '/pos',
        name: 'POS',
        component: Cashier,
        meta: { requiresAuth: true, role: 'cashier', title: 'Cashier' }
    },
    {
        path: '/pos/history',
        name: 'PosHistory',
        component: () => import('../views/pos/History.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'POS History' }
    },
    {
        path: '/pos/inventory',
        name: 'PosInventory',
        component: () => import('../views/pos/Inventory.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'POS Inventory' }
    },
    {
        path: '/pos/products',
        name: 'PosProducts',
        component: () => import('../views/pos/Products.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'Product Catalog' }
    },
    {
        path: '/pos/shifts',
        name: 'PosShifts',
        component: () => import('../views/pos/ShiftHistory.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'Shift History' }
    },
    {
        path: '/pos/settings',
        name: 'PosSettings',
        component: () => import('../views/pos/Settings.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'POS Settings' }
    },
    {
        path: '/pos/members',
        name: 'PosMembers',
        component: () => import('../views/pos/Members.vue'),
        meta: { requiresAuth: true, role: 'cashier', title: 'Member Lookup' }
    },
    // Customer App Routes
    {
        path: '/app',
        name: 'CustomerHome',
        component: () => import('../views/customer/Home.vue'),
        meta: { guest: true, title: 'Home' } 
    },
    {
        path: '/app/order',
        name: 'CustomerMenu',
        component: () => import('../views/customer/Menu.vue'),
        meta: { guest: true, title: 'Menu' }
    },
    {
        path: '/app/product/:id',
        name: 'CustomerProduct',
        component: () => import('../views/customer/Product.vue'),
        meta: { guest: true, title: 'Product Details' }
    },
    {
        path: '/app/payment/:id',
        name: 'CustomerPayment',
        component: () => import('../views/customer/Payment.vue'),
        meta: { guest: true, title: 'Payment' }
    },
    {
        path: '/app/payment/success/:id',
        name: 'CustomerPaymentSuccess',
        component: () => import('../views/customer/PaymentSuccess.vue'),
        meta: { guest: true, title: 'Payment Success' }
    },
    {
        path: '/app/cart',
        name: 'CustomerCart',
        component: () => import('../views/customer/Cart.vue'),
        meta: { guest: true, title: 'My Cart' }
    },
    {
        path: '/app/checkout',
        name: 'CustomerCheckout',
        component: () => import('../views/customer/Checkout.vue'),
        meta: { guest: true, title: 'Checkout' }
    },
    {
        path: '/app/promo',
        name: 'CustomerPromo',
        component: () => import('../views/customer/Promo.vue'),
        meta: { memberAuth: true, title: 'Promos' }
    },
    {
        path: '/app/help',
        name: 'CustomerHelp',
        component: () => import('../views/customer/HelpCenter.vue'),
        meta: { memberAuth: true, title: 'Help Center' }
    },
    // Loyalty
    {
        path: '/app/rewards',
        name: 'CustomerRewards',
        component: () => import('../views/customer/rewards/Index.vue'),
        meta: { memberAuth: true, title: 'Rewards' }
    },
    {
        path: '/app/rewards/:id',
        name: 'CustomerRewardDetail',
        component: () => import('../views/customer/rewards/Show.vue'),
        meta: { memberAuth: true, title: 'Reward Detail' }
    },
    {
        path: '/app/vouchers',
        name: 'CustomerVouchers',
        component: () => import('../views/customer/vouchers/Index.vue'),
        meta: { memberAuth: true, title: 'My Vouchers' }
    },
    {
        path: '/app/vouchers/:id',
        name: 'CustomerVoucherDetail',
        component: () => import('../views/customer/vouchers/Show.vue'),
        meta: { memberAuth: true, title: 'Voucher Detail' }
    },
    // Profile Sub-features
    {
        path: '/app/profile/edit',
        name: 'CustomerProfileEdit',
        component: () => import('../views/customer/profile/EditProfile.vue'),
        meta: { memberAuth: true, title: 'Edit Profile' }
    },

    {
        path: '/app/profile/security',
        name: 'CustomerSecurity',
        component: () => import('../views/customer/profile/Security.vue'),
        meta: { memberAuth: true, title: 'Security' }
    },
    // Member Auth
    {
        path: '/app/login',
        name: 'MemberLogin',
        component: () => import('../views/auth/MemberLogin.vue'),
        meta: { guest: true, title: 'Member Login' }
    },
    {
        path: '/app/register',
        name: 'MemberRegister',
        component: () => import('../views/auth/MemberRegister.vue'),
        meta: { guest: true, title: 'Member Register' }
    },
    {
        path: '/app/verify-otp',
        name: 'MemberVerify',
        component: () => import('../views/auth/MemberVerify.vue'),
        meta: { guest: true, title: 'Verify' } // Technically needs temp state, but 'guest' is fine
    },
    // Legal
    {
        path: '/app/profile/terms',
        name: 'CustomerTerms',
        component: () => import('../views/customer/profile/Terms.vue'),
        meta: { guest: true, title: 'Terms of Service' }
    },
    {
        path: '/app/profile/privacy',
        name: 'CustomerPrivacy',
        component: () => import('../views/customer/profile/Privacy.vue'),
        meta: { guest: true, title: 'Privacy Policy' }
    },
    {
        path: '/app/orders',
        name: 'CustomerOrders',
        component: () => import('../views/customer/Orders.vue'),
        meta: { memberAuth: true, title: 'My Orders' }
    },
    {
        path: '/app/orders/:id',
        name: 'CustomerOrderDetail',
        component: () => import('../views/customer/OrderDetail.vue'),
        meta: { memberAuth: true, title: 'Order Details' }
    },
    {
        path: '/app/orders/:id/receipt',
        name: 'CustomerReceipt',
        component: () => import('../views/customer/Receipt.vue'),
        meta: { memberAuth: true, title: 'Receipt' }
    },
    {
        path: '/app/profile',
        name: 'MemberProfile',
        component: () => import('../views/customer/Profile.vue'),
        meta: { memberAuth: true, title: 'My Profile' }
    },
    {
        path: '/',
        redirect: '/pos' 
    }
];

const router = createRouter({
    history: createWebHistory(),
    routes,
});

// Navigation Guard
router.beforeEach(async (to, from, next) => {
    const authStore = useAuthStore();
    const memberStore = useMemberAuthStore();

    // Member Auth Guard
    if (to.meta.memberAuth && !memberStore.isAuthenticated) {
        next('/app/login');
        return;
    }

    // Check if user is authenticated (mock check for now based on token presence)
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        next('/login');
        return;
    } 
    
    // Guest Guard: Redirect authenticated users away from explicit Guest-Only pages (Login/Register)
    const guestOnlyRoutes = ['Login', 'MemberLogin', 'MemberRegister', 'MemberVerify'];
    if (to.meta.guest && authStore.isAuthenticated && guestOnlyRoutes.includes(to.name)) {
        // If it's a Member trying to access Member Auth pages, redirect to Member Profile or Home
        if (to.name.startsWith('Member')) {
             next('/app');
             return;
        }
        // If it's Staff, go to Dashboard
        next(authStore.hasRole('cashier') ? '/pos' : '/admin');
        return;
    }

    // Role Based Access Control
    if (authStore.isAuthenticated && authStore.user) {
        const userRoles = authStore.user.roles || [];
        const isSuperAdmin = userRoles.some(r => r.name === 'super_admin');
        const isStoreManager = userRoles.some(r => r.name === 'store_manager');
        const isCashier = userRoles.some(r => r.name === 'cashier');

        // Cashier Restrictions
        if (isCashier && to.path.startsWith('/admin')) {
            next('/pos');
            return;
        }

        if (isStoreManager && !isSuperAdmin) {
            const restrictedPaths = ['/admin/users', '/admin/audit-logs', '/admin/settings'];
            if (restrictedPaths.some(path => to.path.startsWith(path))) {
                next('/admin'); // Fallback to dashboard

                return;
            }
        }
    }

    next();
});

router.afterEach((to) => {
    const title = to.meta.title;
    const defaultTitle = 'Ruang Bincang Coffee';
    document.title = title ? `${title} | Ruang Bincang Coffee` : defaultTitle;
});

export default router;
