DROP USER IF EXISTS 'fichajesapp'@'localhost' ;

CREATE USER 'fichajesapp'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON * . * TO 'fichajesapp'@'localhost';
FLUSH PRIVILEGES;

DROP DATABASE if exists fichajesdb;
CREATE DATABASE fichajesdb;

USE `fichajesdb`;

DELIMITER $$

DROP PROCEDURE IF EXISTS daily_task $$

CREATE PROCEDURE daily_task()

BLOCK1: begin
    DECLARE EMPLEADO_DNI varchar(9);
    DECLARE no_more_rows1 Boolean;
    
    DECLARE HORAS_DIARIAS time;
	DECLARE HORA1 time;
	DECLARE HORA2 time;
    
    declare cursor1 cursor for select dni from empleados;
    declare continue handler for not found set no_more_rows1 := TRUE;     				
        
    open cursor1;
    LOOP1: loop
    
        fetch cursor1 into  EMPLEADO_DNI;
        SET HORAS_DIARIAS = 0;
        
        if no_more_rows1 then
            close cursor1;
            leave LOOP1;
        end if;
        
        SET HORAS_DIARIAS = '00:00:00';
        
        BLOCK2: begin
            
            declare no_more_rows2 boolean;
            
            declare cursor2 cursor for SELECT fechaFichaje FROM fichajes WHERE DATE(`fechafichaje`) = CURDATE() AND fichajes.empleado = EMPLEADO_DNI;
			declare continue handler for not found set no_more_rows2 := TRUE;
            
            SET HORA1 = null;
            SET HORA2 = null;
            
            open cursor2;
            LOOP2: loop
            
				SET HORA1 = null;
				SET HORA2 = null;
            
                fetch cursor2 into HORA1;
                fetch cursor2 into HORA2;
                
                if HORA2 is null or HORA1 is null then
					set HORA1 = '00:00:00';
                    set HORA2 = '00:00:00';
                end if;
                
                SET HORAS_DIARIAS = HORAS_DIARIAS + timediff(HORA2, HORA1);
                
                if no_more_rows2 then
                
                    if HORAS_DIARIAS = '00:00:00' then 
						if (select fechaVacaciones from empleados where dni = EMPLEADO_DNI) != curdate() then
							insert into ausencias values (0, curdate(), EMPLEADO_DNI);
                        else
							update empleados set fechaVacaciones = '1111-11-11' where dni = EMPLEADO_DNI;
						end if;
                    end if;
					
                    INSERT INTO historialdiario VALUES (0, CURDATE(), HORAS_DIARIAS, EMPLEADO_DNI);
                    
					if HORAS_DIARIAS > '08:00:00' then						
						if addtime((select empleados.horasADisfrutar from empleados where empleados.dni = EMPLEADO_DNI),(DATE_SUB(HORAS_DIARIAS, INTERVAL 8 HOUR))) < '23:59:59' then
							UPDATE empleados SET empleados.horasADisfrutar = addtime(horasADisfrutar, DATE_SUB(HORAS_DIARIAS, INTERVAL 8 HOUR)) WHERE empleados.dni = EMPLEADO_DNI;
						else
							UPDATE empleados SET empleados.horasADisfrutar = '23:59:59' WHERE empleados.dni = EMPLEADO_DNI;
						end if;
					end if;
                    
                    close cursor2;
                    leave LOOP2;
                end if;
                
            end loop LOOP2;
        end BLOCK2;
        
    end loop LOOP1;
end BLOCK1;
SET FOREIGN_KEY_CHECKS=0;


DROP EVENT if exists event_daily_task;
CREATE EVENT event_daily_task
    ON SCHEDULE EVERY 1 DAY STARTS '2022-06-06 23:55:00'
    DO 
		CALL daily_task();
