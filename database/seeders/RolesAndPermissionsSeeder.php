<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        // create permissions
        $permissions = [
            'view_dashboard',
            'manage_users',
            'manage_products',
            'manage_inventory',
            'pos_access',
            'process_transactions',
            'void_transactions',
            'view_reports',
            'access_settings',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // create roles and assign existing permissions
        $roleSuperAdmin = Role::firstOrCreate(['name' => 'super_admin']);
        $roleSuperAdmin->givePermissionTo(Permission::all());

        $roleStoreManager = Role::firstOrCreate(['name' => 'store_manager']);
        $roleStoreManager->givePermissionTo([
            'view_dashboard',
            'manage_users',
            'manage_products',
            'manage_inventory',
            'pos_access',
            'process_transactions',
            'void_transactions',
            'view_reports',
        ]);

        $roleCashier = Role::firstOrCreate(['name' => 'cashier']);
        $roleCashier->givePermissionTo([
            'pos_access',
            'process_transactions',
            'view_dashboard',
        ]);

        $roleKitchen = Role::firstOrCreate(['name' => 'kitchen']);
        // Kitchen permission logic later

        $roleCustomer = Role::firstOrCreate(['name' => 'customer']);

        // Create Default Super Admin
        $user = User::firstOrCreate(
            ['email' => 'admin@pos.com'],
            [
                'name' => 'Super Admin',
                'username' => 'superadmin',
                'password' => Hash::make('password'),
                'pin_code' => '123456',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $user->assignRole($roleSuperAdmin);
    }
}
