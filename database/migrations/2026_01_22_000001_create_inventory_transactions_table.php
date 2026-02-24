<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_transactions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('ingredient_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['in', 'out', 'adjustment']);
            $table->decimal('quantity', 10, 4); // Amount added/removed
            $table->decimal('unit_cost', 10, 2)->nullable(); // Cost at the time of transaction (for 'in')
            $table->decimal('total_cost', 15, 2)->nullable(); // Total cost (quantity * unit_cost)
            $table->string('reference')->nullable(); // e.g., Purchase Order #, Order #
            $table->text('notes')->nullable();
            $table->foreignUlid('user_id')->constrained(); // Who did it
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_transactions');
    }
};
