FROM alpine:latest 
RUN apk add --no-cache curl 
CMD ["echo", "Spring PetClinic App - Container Running"] 
