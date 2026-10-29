package id.sonora.sonora

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity diperlukan agar pemutaran berlanjut saat aplikasi berada
// di background dan notifikasi media tetap aktif.
class MainActivity : AudioServiceActivity()
