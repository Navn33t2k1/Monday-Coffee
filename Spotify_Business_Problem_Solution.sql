--Schema
CREATE TABLE Spotify(
Artist VARCHAR(255),
Track VARCHAR(255),
Album VARCHAR(255),
Album_type VARCHAR(50),
Danceability FLOAT,
Energy FLOAT,
Loudness FLOAT,
Speechiness	FLOAT,
Acousticness FLOAT,
Instrumentalness FLOAT,
Liveness FLOAT,
Valence	FLOAT,
Tempo FLOAT,
Duration_min FLOAT,
Title VARCHAR(255),
Channel VARCHAR(255),
Views FLOAT,
Likes BIGINT,
Comments BIGINT,
Licensed BOOLEAN,
official_video BOOLEAN,
Stream BIGINT,
EnergyLiveness FLOAT,
most_playedon VARCHAR(50)
);

SELECT *
FROM spotify
LIMIT 100;

-- EDA
--1. check the total number of rows.
SELECT COUNT(*)
FROM spotify;

--2. Check number of artist.
SELECT COUNT(DISTINCT artist)
FROM spotify;

--3. Check number of Albums.
SELECT COUNT(DISTINCT album)
FROM spotify;

--4. Check how many different types of albums.
SELECT DISTINCT album_type
FROM spotify;

--5. Check max and min duration of songs.
SELECT MAX(duration_min) AS maximun_duration, MIN(duration_min) AS minimum_duration
FROM spotify;

-- Songs can not have duration 0. Hence it is better to delete those songs.
SELECT *
FROM spotify
WHERE duration_min=0;

DELETE FROM spotify
WHERE duration_min=0;

--6. Check how many different types of channel.
SELECT DISTINCT channel
FROM spotify;

--7. Check the platform where most most songs are played.
SELECT DISTINCT most_playedon
FROM spotify;

--8. Retrieve the name of all tracks that have more than 1 billion streams.
SELECT track
FROM spotify
WHERE stream > 1000000000;

--9. List all albums along with their respective artists.
SELECT DISTINCT album, artist
FROM spotify
ORDER BY 1;

--10. Get the  total number of comments fro tracks where licensed = TRUE.
SELECT SUM(comments) AS Total_Comments
FROM spotify
WHERE licensed='true';

--11. Find all tracks that belong to the album type single.
SELECT track
FROM spotify
WHERE album_type ILIKE '%single%';

--12. Count the total number of tracks by each artist.
SELECT artist, count(track) AS Total_tracks
FROM spotify
GROUP BY 1
ORDER BY Total_tracks DESC;

--13. Calculate the average danceability of tracks in each album.
SELECT album, AVG(danceability) AS Avg_danceability
FROM spotify
GROUP BY album;

--14. Find the top 5 tracks with the highest energy values
SELECT track, MAX(energy) AS Total_energy
FROM spotify
GROUP BY 1
ORDER BY Total_energy DESC
LIMIT 5;

--15. List all tracks along with their views and likes where official_video = TRUE.
SELECT track, SUM(likes) AS total_likes, SUM(views) AS total_views
FROM spotify
WHERE official_video='true'
GROUP BY track;

--16. For each album, calculate the total views of all associated tracks.
SELECT album, track, SUM(views) AS total_views
FROM spotify
GROUP BY 1, 2;

--17. Retrieve the track names that have been streamed on Spotify more than YouTube.
SELECT *
FROM (SELECT track, COALESCE(SUM(CASE WHEN most_playedon='Youtube' THEN stream END), 0) AS streamed_on_youtube,
COALESCE(SUM(CASE WHEN most_playedon='Spotify' THEN stream END), 0) AS streamed_on_spotify
FROM spotify
GROUP BY 1
ORDER BY 1) AS t1
WHERE streamed_on_spotify > streamed_on_youtube
AND streamed_on_youtube <> 0;

--18. Find the top 3 most-viewed tracks for each artist using window functions.
SELECT *
FROM (SELECT artist, track, SUM(views) AS total_view, DENSE_RANK() OVER(PARTITION BY artist ORDER BY SUM(views) DESC) AS rank
FROM spotify
GROUP BY 1, 2
ORDER BY 1, 3 DESC) AS t1
WHERE rank <=3;

--19. Write a query to find tracks where the liveness score is above the average.
WITH Average AS(
SELECT track, liveness, AVG(liveness) OVER() AS Avg_liveness
FROM spotify)
SELECT *
FROM Average
WHERE liveness > Avg_liveness;

--20. Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.
WITH MaxMin AS(
SELECT album, MAX(energy) AS max_energy, MIN(energy) AS min_energy
FROM spotify
GROUP BY 1)
SELECT album, max_energy - min_energy AS difference
FROM MaxMin;

--21. Find tracks where the energy-to-liveness ratio is greater than 1.2.
WITH energy_to_liveness_ratio AS(
SELECT track, energy/liveness AS ratio
FROM spotify
)
SELECT *
FROM energy_to_liveness_ratio
WHERE ratio > 1.2;

--22. Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.
SELECT track, views, SUM(likes) OVER(ORDER BY likes) AS Cumulative_sum
FROM spotify
WHERE likes <>0
ORDER BY 2;



