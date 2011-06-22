function TpvdEmbed(inputtxtsrc,inputimgsrc,outputimgsrc)
tic;

try
    jpeg=~(isempty(findstr(outputimgsrc,'jpg'))&&isempty(findstr(outputimgsrc,'jpeg')));      %if extension jpeg or jpg found return true
    if(jpeg)
        disp('Unable to write output image file as jpeg is a lossy format...Choose a lossless format');
        fclose('all');
        exit;
    end
catch
    disp('Unable to access output image source...Path incorrect');
    disp('Execution Unsuccessful...Exiting');
    fclose('all');
    exit;
end




%-----------Open Input Text and image-----------%
try
    fid = fopen(inputtxtsrc,'r');
    em = fread(fid);
catch
    disp('Unable to access input text file');
    disp('Execution Unsuccessful...Exiting');
    fclose('all');
    exit;
end

%PRE ALLOCATING VARIABLES
len=length(em);
nd=zeros(3) ; %preallocating for faster runs
in=[];


in=[in dec2bin(len,32)];

for i=1:len
    in=[in dec2bin(em(i),7)];
end

% 
% % in=repmat(false,1,32+(len*7)); %preallocating for faster runs
% 
% 
% % in(1:32)=bitget(len,32:-1:1);        %Put length of message as the first 32 bits in in(k)
% 
% k=32;                                       % 1-32 length...begin from bit 33 onwards
% for i=1:len                              %till end of message
%     in(k+1:k+7) = bitget(em(i),7:-1:1);      %put text into in(k) MSB(7) to LSB(1)
%     k=k+7;
% end

%Finding Capactity
% disp('Calculating image capactity');
capacity(inputimgsrc,len);

a=imread(inputimgsrc);
[r,c]=size(a);
final=double(a);
next=0;
% disp('Starting Embedding...');



%-----------------------Actual TPVD-------------------%
for x=0:2:r-1
    for y=0:2:c-1
        
        %a=[100 126;115 107]
        g=a(1+x:2+x,1+y:2+y);
        g=double(g);
        d0=g(1,2)-g(1,1);
        d1=g(2,1)-g(1,1);
        d2=g(2,2)-g(1,1);
        lk=[0 8 16 32 64 128];
        uk=[7 15 31 63 127 255 ];
        
        d=[d0 d1 d2];
        d=abs(d);
        
        for z=1:3           %z for d1,d2,d3
            for i=1:1:6     %6 bounds in range table
                if (d(z)>=lk(i) && d(z)<=uk(i))
                    w=uk(i)-lk(i)+1;                %width of range
                    t=log2(w);
                    
                    %for last iteration
                    if(next>length(in))
                        k1=zeros(1,t);
                        k=k1;
%                         k=int2str(k);
                        k=bin2dec(k);
                        nd(z)=lk(i)+k;
                    elseif(next+t>length(in))
                        if (1+next>=length(in))        %if exact length and 1+next is = to length(in)
                            k=zeros(1,t);                  %fill with zeros
                        else
                            k=in(1+next:length(in));
                        end
                        diff=next+t-length(in);
                        k1=zeros(1,t);
                        
                        if(diff>0)
                            for j=1:next+t-length(in)
                                k1(j)=k(j);
                            end
                        end
                        k=k1;
                        next=next+t;
                        k=int2str(k);
                        k=bin2dec(k);
                        nd(z)=lk(i)+k;
                    else %otherwise for all iterations
                        k=in(1+next:t+next);
                        next=next+t;
%                         k=int2str(k);
                        k=bin2dec(k);
                        nd(z)=lk(i)+k;
                    end
                end
            end
        end
        nd0=nd(1);
        nd1=nd(2);
        nd2=nd(3);
        
        m0=nd0-d0;
        m1=nd1-d1;
        m2=nd2-d2;
        
        P0=[g(1,1)-ceil(m0/2) g(1,2)+floor(m0/2)];
        P1=[g(1,1)-ceil(m1/2) g(2,1)+floor(m1/2)];
        P2=[g(1,1)-ceil(m2/2) g(2,2)+floor(m2/2)];
        
        
        %--------------5 Rules to minimize Error---------------%
        m=[m0 m1 m2];
        f0=find(m==0);
        f1=find(m==1);
        f2=find(m==-1);
        lf0=length(f0);
        lf1=length(f1);
        lf2=length(f2);
        fp=find(m>0);
        fn=find(m<0);
        %Rule 5
        count=0;
        for i=1:3
            if (m(i)==0 )||( m(i)==1 )||( m(i)==-1)
                count=count+1;
                new(count)=m(i);
                if count>1
                    nm=new(1);
                end
            end
        end
        %Rule 1
        if m<-1
            nm=min(m);
            
        elseif m>1
            nm=max(m);
            
            
            %Rule 2 & 4
        elseif (lf0==1 && lf1==0 && lf2==0) ||(lf0==0 && lf1==1 && lf2==0) ||(lf0==0 && lf1==0 && lf2==1)
            skip=find(m==0 | m==1 | m==-1);
            j=1;
            clear new;  %clearing num
            for i=1:3
                if skip~=i
                    new(j)=m(i);
                    j=j+1;
                end
            end
            if((new(1)>0 && new(2)<0) || (new(2)>1 && new(1)<-1))       %rule 4
                nm=m(skip);
            else
                if new(1)>0                     %rule 2
                    nm=min(new);
                else
                    nm=max(new);
                end
            end
            %rule 3
        elseif(length(fp)==1 && length(fn)==2)
            nm=max(m(fn));
        elseif(length(fp)==2 && length(find(fn)==1))
            nm=min(m(fp));
        end;
        
        pos=find(m==nm);
        if(pos(1)==1)
            P1(1,2)=P1(1,2)+P0(1,1)-P1(1,1);
            P1(1,1)=P0(1,1);
            
            P2(1,2)=P2(1,2)+P0(1,1)-P2(1,1);
            P2(1,1)=P0(1,1);
            
            
        elseif(pos(1)==2)
            P0(1,2)=P0(1,2)+P1(1,1)-P0(1,1);
            P0(1,1)=P1(1,1);
            
            P2(1,2)=P2(1,2)+P1(1,1)-P2(1,1);
            P2(1,1)=P1(1,1);
        else
            P1(1,2)=P1(1,2)+P2(1,1)-P1(1,1);
            P1(1,1)=P2(1,1);
            
            P0(1,2)=P0(1,2)+P2(1,1)-P0(1,1);
            P0(1,1)=P2(1,1);
        end
        
        final(1+x,1+y)=P0(1,1);
        final(1+x,2+y)=P0(1,2);
        final(2+x,1+y)=P1(1,2);
        final(2+x,2+y)=P2(1,2);
        
        if(next>length(in))
            disp('Embedded Successfully...Writing to output image');
            try
                imwrite(uint8(final),outputimgsrc);
            catch
                disp('Unable to write into output image file');
                disp('Execution Unsuccessful...Exiting');
                fclose('all');
                exit;
            end
            
            
            %             subplot(1,2,1);
            %             imshow(a);
            %             title('Cover Image');
            %             subplot(1,2,2);
            %             imshow(uint8(final));
            %             title('Stego Image');
            psnr(inputimgsrc,outputimgsrc);
            fclose('all');
            disp('Success');
            toc;
            return;
        end
    end
end

disp('Error: Text file exceeds capacity of image');
end

function capacity(inputimgsrc,len)

try
    a=imread(inputimgsrc);
catch
    disp('Unable to access input image file');
    disp('Execution Unsuccessful...Exiting');
    fclose('all');
    exit;
end


[r,c]=size(a);
cap=0;
for x=0:2:r-1
    for y=0:2:c-1
        
        g=a(1+x:2+x,1+y:2+y);
        g=double(g);
        d0=g(1,2)-g(1,1);
        d1=g(2,1)-g(1,1);
        d2=g(2,2)-g(1,1);
        lk=[0 8 16 32 64 128];
        uk=[7 15 31 63 127 255 ];
        d=[d0 d1 d2];
        d=abs(d);
        emb=zeros(1,3);
        for z=1:3
            for i=1:1:6
                if (d(z)>=lk(i) && d(z)<=uk(i))
                    w=uk(i)-lk(i)+1;
                    t=log2(w);
                    emb(z)=t;
                    
                end
            end
        end
        if((emb(1)>=5 && emb(2)>=4) || (emb(1)<5 && emb(3)>=6))
            d00=g(1,2)-g(1,1);
            d01=g(2,2)-g(2,1);
            d0=[d00 d01];
            d0=abs(d0);
            for z=1:2
                for i=1:1:6
                    if (d(z)>=lk(i) && d(z)<=uk(i))
                        w=uk(i)-lk(i)+1;
                        t=log2(w);
                        cap=cap+t;
                    end
                end
            end
        else
            cap=cap+emb(1)+emb(2)+emb(3);
        end
    end
end
cap=cap-32;  %subtract 32 bit length
cap=floor(cap/8); %in bytes
disp('Embedding Capacity of image(in bytes)=');
disp(cap);
disp('Length of text file(in bytes)=');
disp(len);

if(cap<len)
    disp('Size of Text to be hidden is greater than Embedding Capacity of the image');
    disp('Choose a larger image');
    fclose('all');
    exit;
end


end

function psnr(inputimgsrc,outputimgsrc)

in=imread(inputimgsrc);
o=imread(outputimgsrc);

[row col] = size(o);

original=double(in);
target=double(o);
mse = 0;
for i=1:row
    for j=1:col
        d1=target(i,j);
        
        d2=original(i,j);
        
        mse=mse+(d1-d2)^2;
    end
end
mse=mse/(row*col);
psnr=10*log10((255^2)/mse);
disp('Noise Introduced (Peak Signal to noise ratio) =');
disp(psnr);
end