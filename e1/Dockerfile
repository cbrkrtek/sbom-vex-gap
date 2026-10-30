FROM ubuntu/jre@sha256:f54ec60b82f1f329371d0ce50de7b223905504f03471b64831b45b91c0b79210
COPY target/spring-petclinic-4.0.0-SNAPSHOT.jar /app/app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
