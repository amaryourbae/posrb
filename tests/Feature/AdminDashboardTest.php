<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test that a super admin can access the dashboard.
     */
    public function test_super_admin_can_access_dashboard()
    {
        // 1. Create the Super Admin Role (and permission if strict, but role check is enough for middleware)
        // Ensure guard matches (usually 'web' for default User model, even with Sanctum)
        $role = Role::create(['name' => 'super_admin', 'guard_name' => 'web']);

        // 2. Create a User and assign the role
        $user = User::factory()->create();
        $user->assignRole($role);

        // 3. Act as the user using Sanctum authentication
        $response = $this->actingAs($user, 'sanctum')
                         ->getJson('/api/admin/dashboard');

        // 4. Assertions
        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'total_sales_today',
                     'transaction_count_today',
                     'low_stock_count',
                     'new_members_count',
                     'date',
                 ]);
    }

    /**
     * Test that a non-admin cannot access the dashboard.
     */
    public function test_regular_user_cannot_access_dashboard()
    {
        $user = User::factory()->create();
        // Do not assign role

        $response = $this->actingAs($user, 'sanctum')
                         ->getJson('/api/admin/dashboard');

        $response->assertStatus(403); // Forbidden
    }
}
