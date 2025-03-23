#!/bin/sh
set -e
#Enable corepack
corepack enable && corepack prepare yarn@4.4.0 --activate
# Run database migrations
echo "Running database migrations..."
npx medusa db:migrate

# Create admin user only if it doesn't exist
echo "Checking if admin user exists..."
npx medusa user -e $ADMIN_EMAIL -p $ADMIN_PASSWORD || {
  echo "Admin user already exists, skipping user creation."
}

# Run seed script only if first-time setup
# If the db is previously seeded, it might make sense to comment this section since the containers to which this file
# is supposed to be copied might be re-created, thus losing the flag file .seed_complete, who's purpose is to make sure
# that if container simply restarts no seed process is being instantiated.
# Otherwise, the error will be thrown during the startup of a new backend container attempting to talk to pre-existing
# seeded database.
if [ ! -f "/app/.seed_complete" ]; then
  echo "Running seed script for first-time setup..."
  npx medusa exec ./src/scripts/seed.ts || {
    echo "Seed script failed, but continuing anyway as data may already exist."
  }
  # Create a flag file to indicate seeding was attempted
  touch /app/.seed_complete
else
  echo "Seed already run previously, skipping."
fi

# Start the application and log output to both console and log file
echo "Starting Medusa server..."
npx medusa start | tee /app/server.log
