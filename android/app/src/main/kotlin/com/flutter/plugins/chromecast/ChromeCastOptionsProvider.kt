package com.flutter.plugins.chromecast

import android.content.Context
import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider

/**
 * Options provider pour configurer Chromecast
 * Utilise le receiver par défaut de Google
 */
class ChromeCastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        return CastOptions.Builder()
            // Utiliser le receiver par défaut de Google
            .setReceiverApplicationId("CC1AD845") // Default Media Receiver
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        return null
    }
}
