FROM httpd:2.4-alpine

# Copy custom configuration if needed
# COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf

# Copy website files
# COPY ./public-html/ /usr/local/apache2/htdocs/

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1
