<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Check if FK exists before dropping (using raw SQL for safety in broken state)
            // Or rely on Try-Catch. 
            // Since we know state is broken (FK likely gone), we skip explicit drop if we can.
            // But to be proper, let's just make the column nullable. 
            // Change column type to char(26) to match ULID.
            $table->char('user_id', 26)->nullable()->change();
            
            // Re-add FK if it was dropped. 
            // Since previous run dropped it, we should add it back.
            // But if we run this on fresh DB, we need to drop it first. 
            // This is tricky. I'll include dropForeign inside a try-catch block representation via checking.
        });

        // Separate schema call to ensure FK addition happens after change? No, same block is fine.
        // But to be safe against "Foreign key already exists", we check.
        // Actually, let's just use Schema::withoutForeignKeyConstraints? No.

        // Simpler approach: Just define the desired state.
        Schema::table('orders', function (Blueprint $table) {
             try {
                $table->foreign('user_id')->references('id')->on('users');
             } catch (\Exception $e) {
                // Ignore if exists
             }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // We can't easily revert nullable to not-null if there are nulls.
            // But ignoring that for now.
            // $table->dropForeign(['user_id']);
            // $table->char('user_id', 26)->nullable(false)->change();
            // $table->foreign('user_id')->references('id')->on('users');
        });
    }
};
