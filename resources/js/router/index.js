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
        path: '/admin/shifts/:id',
        name: 'ShiftShow',
        component: () => import('../views/admin/shifts/Show.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Shift Details' }
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
        path: '/admin/products/:slug/edit',
        name: 'ProductEdit',
        component: () => import('../views/admin/products/Form.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Edit Product' }
    },
    {
        path: '/admin/inventory',
        name: 'Inventory',
        component: () => import('../views/admin/inventory/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Inventory' }
    },
    {
        path: '/admin/units',
        name: 'Units',
        component: () => import('../views/admin/inventory/Units.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Unit Management' }
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
        path: '/admin/settings/updates',
        name: 'AppUpdates',
        component: () => import('../views/admin/settings/AppUpdates.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'App Updates' }
    },
    {
        path: '/admin/reports',
        name: 'Reports',
        component: () => import('../views/admin/reports/Index.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Reports' }
    },
    {
        path: '/admin/reports/profit-loss',
        name: 'ProfitLoss',
        component: () => import('../views/admin/reports/ProfitLoss.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Profit & Loss' }
    },
    {
        path: '/admin/reports/inventory',
        name: 'InventoryReport',
        component: () => import('../views/admin/reports/InventoryReport.vue'),
        meta: { requiresAuth: true, role: 'super_admin', title: 'Stock Report' }
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
        path: '/',
        name: 'CustomerHome',
        component: () => import('../views/customer/Home.vue'),
        meta: { guest: true, title: 'Home' } 
    },
    {
        path: '/order',
        name: 'CustomerMenu',
        component: () => import('../views/customer/Menu.vue'),
        meta: { guest: true, title: 'Menu' }
    },
    {
        path: '/product/:id',
        name: 'CustomerProduct',
        component: () => import('../views/customer/Product.vue'),
        meta: { guest: true, title: 'Product Details' }
    },
    {
        path: '/payment/:id',
        name: 'CustomerPayment',
        component: () => import('../views/customer/Payment.vue'),
        meta: { guest: true, title: 'Payment' }
    },
    {
        path: '/payment/success/:id',
        name: 'CustomerPaymentSuccess',
        component: () => import('../views/customer/PaymentSuccess.vue'),
        meta: { guest: true, title: 'Payment Success' }
    },
    {
        path: '/cart',
        name: 'CustomerCart',
        component: () => import('../views/customer/Cart.vue'),
        meta: { guest: true, title: 'My Cart' }
    },
    {
        path: '/checkout',
        name: 'CustomerCheckout',
        component: () => import('../views/customer/Checkout.vue'),
        meta: { guest: true, title: 'Checkout' }
    },
    {
        path: '/promo',
        name: 'CustomerPromo',
        component: () => import('../views/customer/Promo.vue'),
        meta: { memberAuth: true, title: 'Promos' }
    },
    {
        path: '/help',
        name: 'CustomerHelp',
        component: () => import('../views/customer/HelpCenter.vue'),
        meta: { memberAuth: true, title: 'Help Center' }
    },
    // Loyalty
    {
        path: '/rewards',
        name: 'CustomerRewards',
        component: () => import('../views/customer/rewards/Index.vue'),
        meta: { memberAuth: true, title: 'Rewards' }
    },
    {
        path: '/rewards/:id',
        name: 'CustomerRewardDetail',
        component: () => import('../views/customer/rewards/Show.vue'),
        meta: { memberAuth: true, title: 'Reward Detail' }
    },
    {
        path: '/vouchers',
        name: 'CustomerVouchers',
        component: () => import('../views/customer/vouchers/Index.vue'),
        meta: { memberAuth: true, title: 'My Vouchers' }
    },
    {
        path: '/vouchers/:id',
        name: 'CustomerVoucherDetail',
        component: () => import('../views/customer/vouchers/Show.vue'),
        meta: { memberAuth: true, title: 'Voucher Detail' }
    },
    // Profile Sub-features
    {
        path: '/profile/edit',
        name: 'CustomerProfileEdit',
        component: () => import('../views/customer/profile/EditProfile.vue'),
        meta: { memberAuth: true, title: 'Edit Profile' }
    },

    {
        path: '/profile/security',
        name: 'CustomerSecurity',
        component: () => import('../views/customer/profile/Security.vue'),
        meta: { memberAuth: true, title: 'Security' }
    },
    // Member Auth
    {
        path: '/member/login',
        name: 'MemberLogin',
        component: () => import('../views/auth/MemberLogin.vue'),
        meta: { guest: true, title: 'Member Login' }
    },
    {
        path: '/member/register',
        name: 'MemberRegister',
        component: () => import('../views/auth/MemberRegister.vue'),
        meta: { guest: true, title: 'Member Register' }
    },
    {
        path: '/member/verify-otp',
        name: 'MemberVerify',
        component: () => import('../views/auth/MemberVerify.vue'),
        meta: { guest: true, title: 'Verify' }
    },
    {
        path: '/profile/terms',
        name: 'CustomerTerms',
        component: () => import('../views/customer/profile/Terms.vue'),
        meta: { guest: true, title: 'Terms of Service' }
    },
    {
        path: '/profile/privacy',
        name: 'CustomerPrivacy',
        component: () => import('../views/customer/profile/Privacy.vue'),
        meta: { guest: true, title: 'Privacy Policy' }
    },
    {
        path: '/orders',
        name: 'CustomerOrders',
        component: () => import('../views/customer/Orders.vue'),
        meta: { memberAuth: true, title: 'My Orders' }
    },
    {
        path: '/orders/:id',
        name: 'CustomerOrderDetail',
        component: () => import('../views/customer/OrderDetail.vue'),
        meta: { memberAuth: true, title: 'Order Details' }
    },
    {
        path: '/orders/:id/receipt',
        name: 'CustomerReceipt',
        component: () => import('../views/customer/Receipt.vue'),
        meta: { memberAuth: true, title: 'Receipt' }
    },
    {
        path: '/profile',
        name: 'MemberProfile',
        component: () => import('../views/customer/Profile.vue'),
        meta: { memberAuth: true, title: 'My Profile' }
    },
    {
        path: '/app',
        redirect: '/' 
    },
    {
        // Catch-all for any trailing /app/ routes (e.g. /app/order -> /order)
        path: '/app/:pathMatch(.*)*',
        redirect: to => {
            const pathSegments = to.path.replace(/^\/app\/?/, '');
            
            // Special cases for member auth pages
            if (pathSegments.startsWith('login')) return '/member/login';
            if (pathSegments.startsWith('register')) return '/member/register';
            if (pathSegments.startsWith('verify-otp')) return '/member/verify-otp';
            
            return '/' + pathSegments;
        }
    },
    {
        path: '/:pathMatch(.*)*',
        redirect: '/'
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
        next('/member/login');
        return;
    }

    // Check if user is authenticated (mock check for now based on token presence)
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        next('/login');
        return;
    } 
    
    // Guest Guard: Redirect authenticated users away from explicit Guest-Only pages (Login/Register)
    const guestOnlyRoutes = ['Login', 'MemberLogin', 'MemberRegister', 'MemberVerify'];
    if (to.meta.guest) {
        // Core APP (POS/Admin)
        if (authStore.isAuthenticated && to.name === 'Login') {
             next(authStore.hasRole('cashier') ? '/pos' : '/admin');
             return;
        }
        
        // Member APP
        if (memberStore.isAuthenticated && (to.name === 'MemberLogin' || to.name === 'MemberRegister' || to.name === 'MemberVerify')) {
            next('/');
            return;
        }
    }

    // Role Based Access Control
    if (authStore.isAuthenticated && authStore.user) {
        const userRoles = authStore.user.roles || [];
        const isSuperAdmin = userRoles.some(r => r.name === 'super_admin');
        const isStoreManager = userRoles.some(r => r.name === 'store_manager');
        const isCashier = userRoles.some(r => r.name === 'cashier');
        const isReport = userRoles.some(r => r.name === 'report');

        if (isSuperAdmin) {
            // Super Admin has full open doors
            next();
            return;
        }

        // Store Manager Restrictions
        if (isStoreManager) {
            const restrictedPaths = ['/pos', '/admin/settings', '/admin/audit-logs', '/admin/banners'];
            if (restrictedPaths.some(path => to.path.startsWith(path))) {
                next('/admin');
                return;
            }
        }

        // Cashier Restrictions (Can only access POS, Catalog, Inventory, Customers)
        if (isCashier) {
            const allowedPrefixes = [
                '/pos', 
                '/admin/products', '/admin/categories', '/admin/modifiers', '/admin/discounts',
                '/admin/inventory', '/admin/ingredients', '/admin/units', '/admin/suppliers',
                '/admin/customers'
            ];
            // If they are trying to go somewhere not explicitly allowed and it starts with /admin, block them
            if (to.path.startsWith('/admin') && !allowedPrefixes.some(path => to.path.startsWith(path))) {
                next('/pos');
                return;
            }
        }

        // Report Restrictions (Can only access Catalog, Inventory, Reports)
        if (isReport) {
            const allowedPrefixes = [
                '/admin/products', '/admin/categories', '/admin/modifiers', '/admin/discounts',
                '/admin/inventory', '/admin/ingredients', '/admin/units', '/admin/suppliers',
                '/admin/reports'
            ];
            if ((to.path.startsWith('/admin') || to.path.startsWith('/pos')) && !allowedPrefixes.some(path => to.path.startsWith(path))) {
                next('/admin/reports');
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
