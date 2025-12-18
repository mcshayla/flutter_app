# easiYESt 
*This is meant to be the **easiest** way to plan a wedding*

### Summary:
- The app allows you to explore wedding vendor information such as photographers, catering, and venues. The user can "heart" any vendor to store vendors they love. They can also "diamond" one vendor of each category which shows on a page view meaning they've picked it, this is the one they want. There is also an AI search feature allowing users to give a query and it produces some vendors similar to their query.

### What I learned:
- I had never coded using dart before
- learned how to use fastAPI
- learned about incorporating a database into my application and making decisions about how to set up making database request.


### AI in my project:
- The users are able to search for what wedding they want and the most 4 similar vendors appear.
- I embedded each vendor description and added it to my database.
- Each time a user makes a query, I embed their query using Sentence Transformers
- Then I use cosine similarity to find the 4 most similar vendors in the database and return those to the user. 
- I used SentenceTransformers with this model 'all-mpnet-base-v2', to turn the vendor descriptions into vector embeddings and stored that in Supabase.

### How I used AI to assist buiding this?
- I used AI to talk through my ideas, brainstorming, and thinking about system design.
- I also used AI to help me learn dart and code. I used it it a different browser to force me to type it all though.

### Why this is interesting to me?
-Who doesn't love love? And who doesn't love going to a good wedding?

### Key learnings
1. It's beneficial to make a ERD/database design to avoid refactoring
2. Supabase takes care of so much and was very nice to use
3. There's a difference in using AI and it understanding the context of the vectors vs. recognizing similar words. Different models perform differently.










