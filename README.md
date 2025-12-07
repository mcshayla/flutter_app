# say_yes

# easiYESt 
*his is meant to be the **easiest** way to plan a wedding*

### Summary:
- The app allows you to explore wedding vendor information such as photographers, catering, and venues. The user can "heart" any vendor to store vendors they love. They can also "diamond" one vendor of each category which shows on a page view meaning they've picked it, this is the one they want. There is also an AI search feature allowing users to give a query and it produces some vendors similar to their query.

### What I learned:
- I had never coded using dart before
- learned how to use fastAPI
- learned about incorporating a database into my application and making decisions about how to set up making database request.


### AI in my project:
- I embedded each vendor description and added it to my database.
- Each time a user makes a query, I embed their query.
- Then I use cosine similarity to find the 4 most similar vendors in the database and return those to the user. 
- I used SentenceTransformers with this model 'all-mpnet-base-v2', to turn the vendor descriptions into vector embeddings and stored that in Supabase.

### How I used AI to assist buiding this?
- I used AI to talk through my ideas, brainstorming, and thinking about system design.
- I also asked AI how to do things but I used it in a different tab and I tried not to copy and paste so I would type it myself or as it a broder principle of how to do something and then tried to apply that to my application.

### Why this is interesting to me?
-Who doesn't love love? And who doesn't love going to a good wedding?












