FROM nginx:alpine

# Copy all static files to nginx html directory
COPY index.html /usr/share/nginx/html/
COPY md.html /usr/share/nginx/html/
COPY qr.html /usr/share/nginx/html/
COPY 404.html /usr/share/nginx/html/
COPY sw.js /usr/share/nginx/html/
COPY manifest.json /usr/share/nginx/html/
COPY favicon.ico /usr/share/nginx/html/
COPY favicon.png /usr/share/nginx/html/
COPY icon.png /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
