docker volume create --driver rexray/cinder:latest --opt size=1 --name registry-certs
docker volume create --driver rexray/cinder:latest --opt size=1 --name registry-auth
docker run --rm -it --volume-driver=rexray/cinder:latest -v registry-certs:/certs alpine \
	apk update \
	apk add openssl \
	openssl req -newkey rsa:4096 -nodes -sha256 -keyout /certs/domain.key -x509 -days 365 -out /certs/domain.crt

