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