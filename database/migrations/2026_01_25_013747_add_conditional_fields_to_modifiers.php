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
        Schema::table('modifier_options', function (Blueprint $table) {
            $table->string('name_prefix')->nullable()->after('name');
            $table->string('name_suffix')->nullable()->after('name_prefix');
            $table->string('icon')->nullable()->after('name_suffix');
        });

        Schema::table('product_modifier', function (Blueprint $table) {
            $table->foreignId('condition_modifier_id')->nullable()->after('sort_order')->constrained('modifiers')->nullOnDelete();
            $table->foreignId('condition_option_id')->nullable()->after('condition_modifier_id')->constrained('modifier_options')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('modifier_options', function (Blueprint $table) {
            $table->dropColumn(['name_prefix', 'name_suffix', 'icon']);
        });

        Schema::table('product_modifier', function (Blueprint $table) {
            $table->dropForeign(['condition_modifier_id']);
            $table->dropForeign(['condition_option_id']);
            $table->dropColumn(['condition_modifier_id', 'condition_option_id']);
        });
    }
};
