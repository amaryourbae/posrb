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
        $category = \App\Models\Category::where('name', 'RB Signature')->first();
        if ($category) {
            $category->update(['sort_order' => -1]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $category = \App\Models\Category::where('name', 'RB Signature')->first();
        if ($category) {
            $category->update(['sort_order' => 0]);
        }
    }
};
