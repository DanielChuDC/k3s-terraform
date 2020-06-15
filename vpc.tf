
resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"  
    tags {
        Name = "mainvpc"
    }
}



resource "aws_subnet" "dev-subnet-public-1" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet

}


resource "aws_internet_gateway" "dev-igw" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    tags {
        Name = "dev-igw"
    }
}


resource "aws_route_table" "dev-public-crt" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0"         //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.dev-igw.id}" 
    }
    
    tags {
        Name = "dev-public-crt"
    }
}



resource "aws_route_table_association" "dev-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.dev-subnet-public-1.id}"
    route_table_id = "${aws_route_table.dev-public-crt.id}"
}