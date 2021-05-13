//cisteni ny_trips
create or replace table clean_ny_trips as
with 
cleaning1_trip as
    (select start_time, STOP_TIME, START_STATION_ID, END_STATION_ID, BIKE_ID, count(*) as two_location, MEMBERSHIP_TYPE, USER_TYPE, BIRTH_YEAR, GENDER
        from ny_trips
            group by start_time,STOP_TIME, START_STATION_ID, END_STATION_ID, BIKE_ID, MEMBERSHIP_TYPE, USER_TYPE, BIRTH_YEAR, GENDER
                having count(*) =1),
                
cleaning2_trip as
   (select  start_time, STOP_TIME, START_STATION_ID, END_STATION_ID, BIKE_ID, count(*) as two_location, MEMBERSHIP_TYPE, USER_TYPE, BIRTH_YEAR, GENDER
        from ny_trips
            group by start_time,STOP_TIME, START_STATION_ID, END_STATION_ID, BIKE_ID, MEMBERSHIP_TYPE, USER_TYPE, BIRTH_YEAR, GENDER
                having count(*)>1),
cleaning3_trip as
    (select * from cleaning1_trip
union all
    select  * from cleaning2_trip),

cleaning4_trip as
(select *, date_trunc('hour', start_time::TIMESTAMP_NTZ) as daily_hour
    from cleaning3_trip)
    select * from cleaning4_trip;

/// cisteni ny_station
update ny_stations set station_longitude=replace(station_longitude, '-', '');

create or replace table clean_ny_stations as
with
cleaning1_stations as
    (select * from ny_stations
        where station_latitude!='0' and station_longitude!='0'),
       
cleaning2_stations as
    (select * from cleaning1_stations
        where station_id!='' or station_name!='' or station_latitude!='' or station_longitude!='')
      select * from cleaning2_stations;

create or replace table new_york_rides as
with 
join1 as
    (select cl.*, cs.station_name as name_start, cs.station_latitude as latitude_start, cs.station_longitude as longitude_start  from clean_ny_trips as cl
     left join
     clean_ny_stations as cs
      on cl.start_station_id=cs.station_id),
      
join2 as
    (select j1.*, cs.station_name as name_end, cs.station_latitude as latitude_end, cs.station_longitude as longitude_end  from join1 as j1
     left join 
     clean_ny_stations as cs
      on j1.end_station_id=cs.station_id),
      
join3 as
    (select j2.*, wea.clouds as clouds, wea.temperature as temperature, wea.weather as weather, wea.wind_speed as wind  from join2 as j2
    left join ny_weather as wea
        on j2.daily_hour=wea.date_time),

cleaning as
	(SELECT BIKE_ID, START_TIME, STOP_TIME, START_STATION_ID, NAME_START, LATITUDE_START, LONGITUDE_START, END_STATION_ID, NAME_END, LATITUDE_END, LONGITUDE_END, TEMPERATURE, WEATHER, WIND, MEMBERSHIP_TYPE, USER_TYPE, BIRTH_YEAR, GENDER
        from join3)
        
select *, row_number() over(order by start_time asc) as row_num from cleaning;