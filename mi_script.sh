git config user.name "Dayanna" # configura el nombre de usuario de Git
git config user.email "dagaguancelaca@uide.edu.ec" # configura el correo de Git
git config --list # muestra la configuración actual de Git
rm -rf kernel/build # elimina la carpeta de build del kernel
make setup # prepara el entorno de compilación
ls kernel/build # lista los archivos dentro del build
gunzip -c kernel/build/initramfs.cpio.gz | cpio -t | head -50 # muestra contenido del initramfs comprimido
sed -n '1,200p' scripts/02_build_rootfs.sh # muestra las primeras 200 líneas del script
ln -sf /bin/busybox ${ROOTFS_DIR}/init # crea enlace simbólico de init a busybox
rm -rf kernel/build # elimina nuevamente la carpeta de build

git config user.name "Dayanna" # configura el nombre de usuario de Git
git config user.email "[dagaguancelaca@uide.edu.ec](mailto:dagaguancelaca@uide.edu.ec)" # configura el correo de Git
git config --list # muestra toda la configuración actual de Git

sudo apk add --no-cache flex bison openssl-dev elfutils-dev bc build-base # instala herramientas necesarias para compilar el Kernel
sudo apk add --no-cache libcap-dev binutils-dev zlib-dev # instala librerías adicionales del sistema
sudo apk add --no-cache linux-headers musl-dev # instala encabezados y librerías de Linux
apt-get install -y qemu-system-x86 # instala QEMU para crear la máquina virtual

cd /tmp # entra a la carpeta temporal
wget https://github.com/tukaani-project/xz/releases/download/v5.4.4/xz-5.4.4.tar.gz # descarga el paquete xz
tar xzf xz-5.4.4.tar.gz # descomprime el archivo descargado
cd xz-5.4.4 # entra a la carpeta del programa xz
./configure --prefix=/usr/local # prepara la compilación del programa
make -j2 # compila el programa usando 2 núcleos
make install # instala xz en el sistema

cd /workspaces/copy-fail-challenge-1 # entra al proyecto principal
make setup # descarga y prepara el Kernel Linux y BusyBox

cd kernel/linux # entra a la carpeta del código fuente del Kernel
make bzImage -j2 # compila el Kernel Linux vulnerable
cp arch/x86/boot/bzImage /workspaces/copy-fail-challenge-1/kernel/build/bzImage_vuln # copia el Kernel compilado al directorio build

cp -r /usr/lib/python3.12/* /workspaces/copy-fail-challenge-1/kernel/initramfs/usr/lib/python3.12/ # copia librerías de Python al initramfs
make rootfs # reconstruye el sistema de archivos initramfs

qemu-system-x86_64 -nographic -no-reboot -kernel /workspaces/copy-fail-challenge-1/kernel/build/bzImage_vuln -initrd /workspaces/copy-fail-challenge-1/kernel/build/initramfs.cpio.gz -append "console=ttyS0 quiet STUDENT_ID=Dayanna-Gaguancela" -m 512M -smp 2 # inicia la máquina virtual con el Kernel vulnerable

sed -i 's/# CONFIG_CRYPTO_AUTHENC is not set/CONFIG_CRYPTO_AUTHENC=y/' .config # habilita AUTHENC en el Kernel
sed -i 's/# CONFIG_CRYPTO_SEQIV is not set/CONFIG_CRYPTO_SEQIV=y/' .config # habilita SEQIV en el Kernel
echo "CONFIG_CRYPTO_AUTHENCESN=y" >> .config # agrega AUTHENCESN a la configuración
sed -i 's/# CONFIG_CRYPTO_USER_API_HASH is not set/CONFIG_CRYPTO_USER_API_HASH=y/' .config # habilita USER_API_HASH
make bzImage -j2 # recompila el Kernel con las funciones vulnerables activadas

python3 copy_fail_exp.py # ejecuta el exploit CVE-2026-31431
id # muestra el usuario actual y confirma acceso root

rmmod algif_aead # deshabilita temporalmente el módulo vulnerable
lsmod | grep algif_aead # verifica que el módulo ya no esté cargado
echo "install algif_aead /bin/false" > /etc/modprobe.d/disable-algif.conf # bloquea permanentemente el módulo tras reiniciar

grep -n "aead_request_set_crypt" kernel/linux/crypto/algif_aead.c # busca la línea vulnerable en el código fuente
sed -i '282s/aead_request_set_crypt(&areq->cra_u.aead_req, rsgl_src,/aead_request_set_crypt(&areq->cra_u.aead_req, areq->tsgl,/' kernel/linux/crypto/algif_aead.c # aplica el parche al Kernel separando src y dst

git diff crypto/algif_aead.c > /workspaces/copy-fail-challenge-1/patches/fix_algif_aead.patch # guarda el parche generado en un archivo .patch
make bzImage -j2 # recompila el Kernel parcheado
cp arch/x86/boot/bzImage /workspaces/copy-fail-challenge-1/kernel/build/bzImage_patched # copia el nuevo Kernel parcheado al directorio build

git add . # agrega todos los cambios al área de preparación
git commit -m "hito completado" # guarda los cambios realizados en Git
git push # sube todos los cambios al repositorio de GitHub
