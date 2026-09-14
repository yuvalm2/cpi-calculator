# cpi-calculator — static site (CPI linkage calculator + monthly index table).
# No build step: just serve the HTML with nginx.
FROM nginx:1-alpine3.24

# Drop the default site and copy ours in. The repo root is the web root.
RUN rm -rf /usr/share/nginx/html/*
COPY . /usr/share/nginx/html/

EXPOSE 80
