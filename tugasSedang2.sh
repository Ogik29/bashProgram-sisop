#!/bin/bash

# Warna Teks
MERAH='\033[0;31m'
HIJAU='\033[0;32m'
KUNING='\033[0;33m'
BIRU='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
PUTIH='\033[0;97m'

# Reset Warna
NC='\033[0m'
 
# Gaya Teks
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Fungsi untuk menampilkan garis pemisah
draw_line() {
    # Perintah ini membuat sebaris spasi kosong selebar terminal,
    # lalu pipe '|' mengirimkannya ke perintah 'tr'.
    # Perintah 'tr' kemudian mengganti setiap karakter spasi (' ') dengan
    # karakter sama dengan ('=').
    printf "${BIRU}%*s${NC}\n" "${COLUMNS:-$(tput cols)}" "" | tr ' ' '='
}

tampilkan_header() {
    clear
    draw_line
    figlet "Acumalaka App"
    printf "${PUTIH}Tugas Sedang Sisop :3${NC}\n"
    draw_line
}

tampilkan_menu() {
    echo ""
    printf " ${BOLD}${PUTIH}Pilih salah satu opsi:${NC}${NORMAL}\n"
    printf " ${KUNING}1.${NC} Tampilkan Waktu Saat Ini\n"
    printf " ${KUNING}2.${NC} Tampilkan Daftar Direktori\n"
    printf " ${KUNING}3.${NC} Tampilkan Informasi Jaringan\n"
    printf " ${KUNING}4.${NC} Tampilkan Detail Sistem Operasi\n"
    printf " ${KUNING}5.${NC} Tampilkan Waktu Instalasi OS\n"
    printf " ${KUNING}6.${NC} Informasi Pengguna Sistem\n"
    printf " ${KUNING}7.${NC} Keluar\n"
    echo ""
    draw_line
}

# Fungsi untuk menampilkan judul di setiap menu aksi
tampilkan_judul_aksi() {
    clear
    printf "${CYAN}${BOLD}### %s ###${NC}${NORMAL}\n\n" "$1"
}

# Fungsi untuk opsi 1: Menampilkan tanggal dan waktu saat ini
kehidupan_saat_ini() {
    tampilkan_judul_aksi "Kehidupan Saat Ini"
    printf "${PUTIH}Tanggal dan Waktu Sistem Saat Ini:${NC}\n"
    # 'date' adalah perintah Linux untuk menampilkan tanggal dan waktu sistem saat ini.
    echo -e "${HIJAU}$(date)${NC}"
}

# Fungsi untuk opsi 2: Menampilkan daftar file dan direktori
daftar_direktori() {
    tampilkan_judul_aksi "Daftar Direktori Saat Ini"
    # '$(pwd)' adalah "command substitution". Perintah 'pwd' (Print Working Directory) akan dieksekusi terlebih dahulu, dan hasilnya (path direktori saat ini) akan disisipkan ke dalam string echo.
    printf "${PUTIH}Isi dari direktori: ${KUNING}$(pwd)${NC}\n\n"
    # 'ls -lhA' adalah perintah untuk menampilkan daftar isi direktori.
    # -l : long format (menampilkan detail lengkap).
    # -h : human-readable (ukuran file dalam KB, MB, agar mudah dibaca).
    # -A : all (menampilkan semua file, termasuk yang tersembunyi, kecuali '.' dan '..').
    # ls dengan opsi --color=auto akan memberi warna secara otomatis
    ls -lhA --color=auto
}

# Fungsi untuk opsi 3: Menampilkan informasi jaringan
info_jaringan() {
    tampilkan_judul_aksi "Informasi Jaringan"
    echo -e "${KUNING}Mengambil data jaringan dan lokasi, plis sabar...${NC}\n"
    
    # Cara ini dapat menemukan nama interface utama yang terhubung ke internet (misalnya enp0s3, wlan0, dll) secara otomatis.
    ACTIVE_INTERFACE=$(ip route | grep default | awk '{print $5}')
    
    # Jika tidak ada interface aktif yang ditemukan, keluar dari fungsi dengan pesan.
    if [ -z "$ACTIVE_INTERFACE" ]; then
        echo -e "${MERAH}Tidak dapat menemukan interface jaringan yang aktif.${NC}"
        return
    fi
    
    # Mengambil Alamat IP Lokal dari interface yang aktif.
    IP_LOKAL=$(ip -4 addr show $ACTIVE_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # Mengambil Gateway default.
    GATEWAY=$(ip r | grep default | awk '{print $3}')
    
    # Mengambil Netmask dalam format CIDR (/24) dari interface yang aktif.
    NETMASK_CIDR=$(ip -4 addr show $ACTIVE_INTERFACE | grep -oP '(?<=inet\s)[\d./]+' | cut -d'/' -f2)
    
    # Mengambil DNS Server dari systemd-resolved (cara modern di Ubuntu).
    # 'paste -sd " "' digunakan untuk menggabungkan beberapa DNS server menjadi satu baris.
    DNS_SERVER=$(resolvectl status $ACTIVE_INTERFACE | grep 'DNS Servers' | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//' | paste -sd " ")
    # Fallback jika cara di atas gagal, coba baca dari /etc/resolv.conf.
    if [ -z "$DNS_SERVER" ]; then
        DNS_SERVER=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | paste -sd " ")
    fi

    printf "${CYAN}%-15s${NC} : ${HIJAU}%s${NC}\n" "Alamat IP Lokal" "${IP_LOKAL:-N/A}"
    printf "${CYAN}%-15s${NC} : %s\n" "Gateway" "${GATEWAY:-N/A}"
    printf "${CYAN}%-15s${NC} : %s\n" "Netmask" "${IP_LOKAL:-N/A}/${NETMASK_CIDR:-N/A}"
    printf "${CYAN}%-15s${NC} : %s\n\n" "DNS Server(s)" "${DNS_SERVER:-N/A}"
    
    # cek koneksi internet dengan mengirim satu paket ping ke server DNS Google.
    printf "${CYAN}Status Koneksi ke Internet:${NC}\n"
    # '-c 1' kirim 1 paket, '-W 2' tunggu balasan maks 2 detik.
    # '&> /dev/null' sembunyikan semua output dari perintah ping.
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e " ${HIJAU} Tersambung ke Internet.${NC}"
    else
        echo -e " ${MERAH} Tidak Tersambung ke Internet.${NC}"
    fi
    echo ""

    # Menampilkan status koneksi perangkat menggunakan NetworkManager command-line tool.
    printf "${CYAN}Status Koneksi LAN/WIFI:${NC}\n"
    nmcli device status
    echo ""
    
    printf "${CYAN}Lokasi IP (berdasarkan IP Publik):${NC}\n"
    # cek apakah perintah 'curl' terinstall (install curl terlebih dahulu)
    if command -v curl &> /dev/null; then
        # Menggunakan curl untuk meminta data lokasi ke ipinfo.io secara terpisah.
        # '-s' untuk silent mode (tidak menampilkan progress bar).
        CITY=$(curl -s ipinfo.io/city)
        REGION=$(curl -s ipinfo.io/region)
        COUNTRY=$(curl -s ipinfo.io/country)
        if [ -n "$CITY" ] && [ -n "$REGION" ]; then
            echo -e " ${HIJAU}$CITY, $REGION, $COUNTRY${NC}"
        else
            echo -e " ${MERAH}Gagal mengambil data lokasi. Periksa koneksi internet Anda.${NC}"
        fi
    else
        echo -e " ${MERAH}Perintah 'curl' tidak ditemukan. Mohon install (sudo apt install curl).${NC}"
    fi
}

# Fungsi untuk opsi 4: Menampilkan Detail Sistem Operasi
detail_os() {
    tampilkan_judul_aksi "Detail Sistem Operasi"
    
    # Memeriksa apakah file /etc/os-release ada. Ini adalah cara standar di sistem modern untuk mendapatkan informasi tentang distribusi Linux.
    if [ -f /etc/os-release ]; then
        # Memuat variabel dari file tersebut (seperti NAME, VERSION, dll.) ke dalam environment shell saat ini.
        . /etc/os-release
        printf "${CYAN}%-12s${NC} : %s\n" "Nama OS" "$NAME"
        printf "${CYAN}%-12s${NC} : %s\n" "Versi" "$VERSION"
        printf "${CYAN}%-12s${NC} : %s\n" "ID" "$ID"
        printf "${CYAN}%-12s${NC} : %s\n\n" "Versi ID" "$VERSION_ID"
    else
        echo -e "${MERAH}Informasi OS tidak dapat ditemukan di /etc/os-release.${NC}\n"
    fi

    # 'uname -r' adalah perintah untuk mencetak rilis kernel yang sedang berjalan.
    printf "${CYAN}Informasi Kernel:${NC}\n %s\n\n" "$(uname -r)"
    
    # Menggunakan 'top' dalam mode batch ('-b') untuk satu kali iterasi ('-n1').
    # Outputnya kemudian disalurkan ('|') ke 'grep' untuk menyaring
    # hanya baris yang berisi '%Cpu(s)'.
    # 'sed' digunakan untuk menghapus spasi kosong yang mungkin ada di awal baris.
    printf "${CYAN}Proses CPU Terakhir:${NC}\n %s\n\n" "$(top -bn1 | grep '%Cpu(s)' | sed 's/^[ \t]*//')"
    
    printf "${CYAN}Penggunaan Memori:${NC}\n"
    # 'free -h' adalah perintah untuk menampilkan jumlah total, terpakai, dan sisa memori (RAM dan Swap) dalam format yang mudah dibaca (KB, MB, GB).
    free -h
    
    echo ""
    printf "${CYAN}Penggunaan Disk:${NC}\n"
    # 'df -h' adalah perintah untuk menampilkan laporan penggunaan ruang disk pada setiap filesystem dalam format Human-readable.
    df -h
}

# Fungsi untuk opsi 5: Menampilkan Waktu Instalasi OS
waktu_install_os() {
    tampilkan_judul_aksi "Waktu Instalasi OS (Berdasarkan Waktu Pembuatan Filesystem)"
    
    # menggunakan metode pengecekan Waktu Pembuatan Filesystem
    # Metode ini memeriksa kapan partisi root ('/') diformat, yang biasanya terjadi tepat sebelum OS diinstal.
    echo -e "${KUNING}Mencari waktu instalasi pertama kali${NC}\n"
    # 'df /' mencari partisi root, 'awk' mengambil namanya (misal: /dev/sda1)
    ROOT_DEVICE=$(df / | awk 'NR==2{print $1}')
    # 'tune2fs -l' membaca metadata filesystem.
    FS_CREATE_DATE=$(sudo tune2fs -l "$ROOT_DEVICE" 2>/dev/null | grep 'Filesystem created:')
    
    if [ -n "$FS_CREATE_DATE" ]; then
        printf "${PUTIH}Perkiraan waktu instalasi (berdasarkan Waktu Pembuatan Filesystem):${NC}\n"
        # Membersihkan output agar hanya menampilkan tanggalnya.
        CREATE_DATE_FORMATTED=$(echo "$FS_CREATE_DATE" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')
        echo -e "${HIJAU}$CREATE_DATE_FORMATTED${NC}"
    else
        echo -e "${MERAH}Gagal menentukan waktu instalasi OS.${NC}"
    fi
}

# Fungsi untuk opsi 6: Menampilkan informasi tentang user 
info_user() {
    tampilkan_judul_aksi "Informasi Pengguna Sistem"

    # Mendapatkan Nama Lengkap dari field GECOS di file password.
    # 'getent passwd' mengambil data user, lalu 'cut -d: -f5' mengambil field ke-5 (Nama Lengkap, dll).
    # Bagian 'cut -d, -f1' mengambil hanya bagian pertama sebelum koma, yaitu nama lengkap.
    NAMA_LENGKAP=$(getent passwd $(whoami) | cut -d: -f5 | cut -d, -f1)
    # Jika nama lengkap belum diatur (kosong), maka gunakan username sebagai gantinya
    if [ -z "$NAMA_LENGKAP" ]; then
        NAMA_LENGKAP=$(whoami)
    fi

    printf "${CYAN}%-15s${NC} : %s\n" "Username" "$(whoami)"
    printf "${CYAN}%-15s${NC} : %s\n" "User ID" "$(id -u)"
    # 'id -g' digunakan untuk mendapatkan ID grup primer (primary group ID) pengguna.
    printf "${CYAN}%-15s${NC} : %s\n" "Group ID" "$(id -g)"
    printf "${CYAN}%-15s${NC} : %s\n" "Group User" "$(id -Gn)"
    printf "${CYAN}%-15s${NC} : %s\n" "Nama Lengkap" "$NAMA_LENGKAP"
    printf "${CYAN}%-15s${NC} : %s\n" "Shell" "$SHELL"
    printf "${CYAN}%-15s${NC} : %s\n" "Home Directory" "$HOME"
}


# LOOP UTAMA PROGRAM
while true; do
    tampilkan_header
    tampilkan_menu

    # Prompt input dengan warna
    read -p "$(echo -e "${MAGENTA}${BOLD}Masukkan pilihan Anda [1-7]: ${NORMAL}${NC}")" pilihan

    # Memulai case setelah membersihkan layar untuk tampilan hasil yang fokus
    case $pilihan in
        1) 
            kehidupan_saat_ini 
            ;;
        2) 
            daftar_direktori 
            ;;
        3) 
            info_jaringan 
            ;;
        4) 
            detail_os 
            ;;
        5) 
            waktu_install_os 
            ;;
        6) 
            info_user 
            ;;
        7)
            clear
            draw_line
            echo -e "\n${HIJAU}Terima kasih telah menggunakan Acumalaka App. Gud Bai :v${NC}\n"
            draw_line
            exit 0
            ;;
        *)
            # Pesan error dengan warna merah
            echo -e "\n${MERAH}Pilihan tidak valdi. Silakan coba lagi.${NC}"
            ;;
    esac

    echo ""
    draw_line
    read -p "$(echo -e "${MAGENTA}Tekan [Enter] untuk kembali ke menu...${NC}")"
done
