function TpvdExtract(inputimgsrc,outputtxtsrc)
tic;
msg=[];
flag=0;

disp('Starting Extraction Process...');

try
    a=imread(inputimgsrc);
catch
    disp('Unable to access input image file');
    disp('Execution Unsuccessful...Exiting');
    fclose('all');
    exit;
end
[r,c]=size(a);
%figure;
%imshow(a);
%title('original image');
%final=double(a);
j=0;
length=5*7; %Intially assuming we have 5 letters

%-----------------------Actual Extraction-------------------%
disp('Extracting...');
for x=0:2:r-2
    for y=0:2:c-2

        %a=[100 126;115 107]
        g=a(1+x:2+x,1+y:2+y);
        g=double(g);
        nd0=abs(g(1,1)-g(1,2));
        nd1=abs(g(1,1)-g(2,1));
        nd2=abs(g(1,1)-g(2,2));
        lk=[0 8 16 32 64 128];
        uk=[7 15 31 63 127 255 ];

        nd=[nd0 nd1 nd2];
        for z=1:3
            for i=1:1:6
                if (nd(z)>=lk(i) && nd(z)<=uk(i))
                    w=uk(i)-lk(i)+1;
                    t=log2(w);

                    b(z)=nd(z)-lk(i);
                    k=dec2bin(b(z),t);
                    msg=[msg k];
                    j=j+t;
                    
                    if(flag==0 && j>=32)
                        length=bin2dec(msg(1:32))+5;  %%%%%%%%%%%%%POSSIBLE ERROR 5 char less
                        length=length*7;
                        flag=1;
                    end
                       
                    if(j>=length)
                        j=1;
%                        finaltxt=zeros(length/7); %PRE ALLOCATING
                        for i=32:7:length-7
                            finaltxt(j)=bin2dec(msg(1+i:7+i));
                            j=j+1;
                        end
                        
%                        disp(char(finaltxt));
                        %for converting binary sequence to characters
                        try
                            fid=fopen(outputtxtsrc,'w');
                            fwrite(fid,finaltxt);
                            disp('Message Extracted and saved to-')
                            disp(outputtxtsrc);
                        catch
                            disp('Unable to write into output text file');
                            disp('Execution Unsuccessful...Exiting');
                            fclose('all');
                            exit;
                        end
                        %writing in the o/p file
                        fclose('all');
                        disp('Success');
                        toc;
                        return;
                    end
                end
            end
        end
    end
end
disp('Error: Abnormal termination');
end

