<?php

use Illuminate\Support\Facades\Route;

Route::get('/app/{any}', function ($any) {
    if ($any === 'login') {
        return redirect('/member/login', 301);
    }
    if ($any === 'register') {
        return redirect('/member/register', 301);
    }
    return redirect('/' . $any, 301);
})->where('any', '.*');

Route::view('/{any}', 'welcome')->where('any', '.*');
