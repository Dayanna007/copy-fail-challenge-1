# Reporte Técnico — CVE-2026-31431 "Copy Fail"

## 1. ¿Cuál es el bug raíz y en qué archivo/función está?

El bug está en el archivo `crypto/algif_aead.c`, en la función `_aead_recvmsg()`. El problema fue introducido en 2017 como una optimización: se usó `sg_chain()` para encadenar las páginas del TX SGL al final del RX SGL, y luego se hizo `req->src = req->dst`, es decir, el mismo scatterlist se usaba tanto como fuente como destino de la operación criptográfica AEAD.

## 2. ¿Por qué el write a dst[assoclen + cryptlen] es peligroso?

Cuando src y dst apuntan al mismo scatterlist y ese scatterlist contiene páginas del page cache de un binario setuid (como `/usr/bin/su`), la operación AEAD puede escribir datos controlados por el atacante directamente en esas páginas en memoria, sin tocar el archivo en disco. Esto corrompe el binario en memoria de forma que cuando se ejecuta, el kernel carga la versión modificada y otorga privilegios de root.

## 3. ¿Por qué el exploit es "stealthy"?

El exploit no modifica el archivo en disco. Solo corrompe el page cache en memoria RAM. Esto significa que herramientas como `sha256sum` sobre el archivo en disco mostrarán el hash original correcto. No hay escritura en disco, por lo que sistemas de detección basados en integridad de archivos no detectan el ataque. Al reiniciar la VM, el page cache se limpia y el binario vuelve a su estado original.

## 4. Conexión con conceptos del curso

- **Page cache**: El kernel mantiene en RAM copias de archivos del disco para acceso rápido. El exploit escribe en esta caché sin tocar el disco.
- **chmod y setuid**: `/bin/su` tiene el bit setuid activado (`chmod u+s`), lo que significa que se ejecuta con los privilegios del dueño (root), no del usuario que lo llama.
- **Inodos**: El inodo del archivo apunta a las páginas en el page cache. El exploit manipula esas páginas directamente mediante AF_ALG y splice().
- **AF_ALG**: Es la interfaz del kernel para operaciones criptográficas desde userspace. El exploit abusa de esta interfaz para obtener acceso de escritura al page cache.

## 5. ¿Qué aprendí sobre bugs compuestos?

Este CVE demuestra que múltiples cambios individualmente razonables pueden combinarse para crear una vulnerabilidad grave. La optimización de 2017 tenía sentido en su contexto, pero ignoró que los scatterlists podían apuntar a páginas del page cache de binarios privilegiados. El bug estuvo presente casi una década porque ninguna prueba individual lo detectaba: requería la combinación específica de AF_ALG + authencesn + splice() + binario setuid. Esto enseña que la seguridad del kernel requiere analizar no solo cada cambio aislado, sino las interacciones entre subsistemas.
